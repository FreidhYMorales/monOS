#!/usr/bin/env bash
# monOS installer: remove drivers and guest tools this machine does not need.
#
# Usage (Calamares shellprocess@hardware, dontChroot): monos-hardware-cleanup.sh <target-root>
#
# The live root filesystem ships every driver so the live session works
# anywhere; the installed system only keeps what the hardware uses. Detection
# runs on the live system (same machine), removal with pacman in the target.
#
#   NVIDIA   no NVIDIA GPU, or only GPUs older than Turing (not supported by
#            the open kernel modules; nouveau drives them)
#            -> remove nvidia-open, nvidia-open-lts, nvidia-utils,
#               libva-nvidia-driver (and their now unused dependencies)
#            Detection: /usr/local/lib/monos/nvidia-open-supported.
#   Intel    CPU vendor is not GenuineIntel -> disable and remove thermald
#            no Intel display controller   -> remove intel-media-driver
#   VM       bare metal -> disable and remove every guest tool (open-vm-tools,
#            qemu-guest-agent, virtualbox-guest-utils-nox, hyperv)
#            known hypervisor -> keep only its guest tools
#            unknown hypervisor -> keep them all
#
# Runs after shellprocess@cleanup and before the packages module, snapper and
# initcpio. mkinitcpio's pacman hook is masked during the removal: the
# initcpio module rebuilds every initramfs afterwards anyway.
set -euo pipefail

ROOT="${1:-}"
if [[ -z "${ROOT}" || "${ROOT}" == "/" || ! -d "${ROOT}/etc" ]]; then
    echo "error: usage: $0 <target-root> (got '${ROOT}')" >&2
    exit 1
fi

log() { printf 'monos-hardware: %s\n' "$*"; }
in_target() { chroot "${ROOT}" "$@"; }

remove_pkgs=()
disable_units=()

# True when a PCI display controller (class 0x03xxxx) of vendor $1 exists.
has_display_vendor() {
    local dev
    for dev in /sys/bus/pci/devices/*; do
        [[ -r "${dev}/vendor" && -r "${dev}/class" ]] || continue
        [[ "$(<"${dev}/vendor")" == "$1" && "$(<"${dev}/class")" == 0x03* ]] && return 0
    done
    return 1
}

# --- NVIDIA -------------------------------------------------------------------
nvidia_rc=0
MONOS_NVIDIA_CHIPS="${ROOT}/usr/share/doc/nvidia/html/supportedchips.html" \
    /usr/local/lib/monos/nvidia-open-supported -v || nvidia_rc=$?
case "${nvidia_rc}" in
    0) log "NVIDIA GPU supported by nvidia-open: keeping the NVIDIA driver" ;;
    1) log "NVIDIA GPU older than Turing: removing the NVIDIA driver (nouveau is used)"
       remove_pkgs+=(nvidia-open nvidia-open-lts nvidia-utils libva-nvidia-driver) ;;
    2) log "no NVIDIA GPU: removing the NVIDIA driver"
       remove_pkgs+=(nvidia-open nvidia-open-lts nvidia-utils libva-nvidia-driver) ;;
    *) log "warning: NVIDIA detection failed (exit ${nvidia_rc}): keeping the NVIDIA driver" ;;
esac

# --- Intel ----------------------------------------------------------------------
if grep -q '^vendor_id[[:space:]]*:[[:space:]]*GenuineIntel' /proc/cpuinfo; then
    log "Intel CPU: keeping thermald"
else
    log "non-Intel CPU: removing thermald"
    disable_units+=(thermald.service)
    remove_pkgs+=(thermald)
fi
if has_display_vendor 0x8086; then
    log "Intel GPU: keeping intel-media-driver"
else
    log "no Intel GPU: removing intel-media-driver"
    remove_pkgs+=(intel-media-driver)
fi

# --- Virtual machine guest tools -------------------------------------------------
virt="$(systemd-detect-virt --vm 2>/dev/null || true)"
virt="${virt:-none}"
declare -A guest_pkg=(
    [vmware]=open-vm-tools
    [kvm]=qemu-guest-agent
    [oracle]=virtualbox-guest-utils-nox
    [microsoft]=hyperv
)
declare -A guest_units=(
    [vmware]="vmtoolsd.service vmware-vmblock-fuse.service"
    [kvm]="qemu-guest-agent.service"
    [oracle]="vboxservice.service"
    [microsoft]="hv_fcopy_daemon.service hv_kvp_daemon.service hv_vss_daemon.service"
)
keep=""
case "${virt}" in
    none) log "bare metal: removing all VM guest tools" ;;
    vmware|oracle|microsoft) keep="${virt}" ;;
    kvm|qemu) keep=kvm ;;
    *) keep=all ;;
esac
if [[ "${keep}" == all ]]; then
    log "virtual machine (${virt}): keeping all guest tools"
else
    if [[ -n "${keep}" ]]; then
        log "virtual machine (${virt}): keeping ${guest_pkg[${keep}]} only"
    fi
    for hv in vmware kvm oracle microsoft; do
        [[ "${hv}" == "${keep}" ]] && continue
        remove_pkgs+=("${guest_pkg[${hv}]}")
        read -r -a units <<<"${guest_units[${hv}]}"
        disable_units+=("${units[@]}")
    done
fi

# --- Apply ------------------------------------------------------------------------
installed=()
for pkg in "${remove_pkgs[@]}"; do
    if in_target pacman -Q -- "${pkg}" >/dev/null 2>&1; then
        installed+=("${pkg}")
    fi
done
if ((${#installed[@]} == 0)); then
    log "nothing to remove"
    exit 0
fi

# Remove enablement symlinks first (pacman does not remove them).
for unit in "${disable_units[@]}"; do
    if [[ -e "${ROOT}/usr/lib/systemd/system/${unit}" ]]; then
        in_target systemctl disable --quiet -- "${unit}" || log "warning: could not disable ${unit}"
    fi
done

# Mask mkinitcpio's install hook for this transaction (a hook in
# /etc/pacman.d/hooks with the same name overrides it; /dev/null disables it).
hooks_dir="${ROOT}/etc/pacman.d/hooks"
mask="${hooks_dir}/90-mkinitcpio-install.hook"
masked=0
if [[ ! -e "${mask}" && ! -L "${mask}" ]]; then
    install -d -m 0755 -- "${hooks_dir}"
    ln -s /dev/null "${mask}"
    masked=1
fi
unmask() { if ((masked)); then rm -f -- "${mask}"; fi; }
trap unmask EXIT

log "removing: ${installed[*]}"
if ! in_target pacman -Rns --noconfirm -- "${installed[@]}"; then
    # Something still needs one of them: remove the others one by one.
    log "warning: removing them together failed, trying one by one"
    for pkg in "${installed[@]}"; do
        in_target pacman -Q -- "${pkg}" >/dev/null 2>&1 || continue
        in_target pacman -Rns --noconfirm -- "${pkg}" || log "warning: could not remove ${pkg}"
    done
fi

log "done"
