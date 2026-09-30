#!/usr/bin/env bash
# monOS installer: turn the copied live root filesystem into an installed system.
#
# Usage (Calamares shellprocess@cleanup, dontChroot): monos-target-cleanup.sh <target-root>
#
# Runs after unpackfs/fstab/locale and before initcpiocfg/initcpio, so that
# mkinitcpio on the target no longer sees the archiso configuration.
#
# 1. Removes live-session-only files: SDDM autologin, liveuser sudo/sysusers
#    rules, archiso mkinitcpio drop-in/presets, live-only systemd units and
#    their enablement symlinks, helper scripts, the installer launcher and
#    this Calamares configuration.
# 2. Restores the kernels: mkarchiso empties /boot of the live root filesystem
#    (kernels and initramfs only exist on the ISO). Every kernel package also
#    ships its image as /usr/lib/modules/<version>/vmlinuz with a "pkgbase"
#    file next to it, which is exactly what mkinitcpio's pacman hook copies to
#    /boot/vmlinuz-<pkgbase>. We do the same for every installed kernel
#    (linux and linux-lts) and recreate the default mkinitcpio presets from
#    mkinitcpio's template. This does not depend on the ISO being mounted.
# 3. Initializes a fresh pacman keyring (on the live system it is a tmpfs, so
#    the copied /etc/pacman.d/gnupg is empty or unusable).
set -euo pipefail

ROOT="${1:-}"
if [[ -z "${ROOT}" || "${ROOT}" == "/" || ! -d "${ROOT}/etc" ]]; then
    echo "error: usage: $0 <target-root> (got '${ROOT}')" >&2
    exit 1
fi

log() { printf 'monos-cleanup: %s\n' "$*"; }
in_target() { chroot "${ROOT}" "$@"; }

# --- 1. Live-only files ------------------------------------------------------
log "removing live-session files"
live_files=(
    etc/sddm.conf.d/autologin.conf
    etc/sudoers.d/liveuser
    etc/sysusers.d/monos-liveuser.conf
    etc/mkinitcpio.conf.d/archiso.conf
    etc/systemd/journald.conf.d/volatile-storage.conf
    etc/systemd/logind.conf.d/do-not-suspend.conf
    etc/systemd/resolved.conf.d/archiso.conf
    etc/systemd/system-generators/systemd-gpt-auto-generator
    etc/motd
    root/.automated_script.sh
    root/.zlogin
    usr/local/bin/choose-mirror
    usr/local/bin/Installation_guide
    usr/local/bin/livecd-sound
    usr/local/bin/monos-install
    usr/local/share/applications/monos-install.desktop
    usr/local/share/applications/calamares.desktop
)
for f in "${live_files[@]}"; do
    rm -f -- "${ROOT:?}/${f}"
done
rm -rf -- "${ROOT:?}/usr/local/share/livecd-sound" "${ROOT:?}/etc/calamares"

# archiso presets (linux.preset only builds the "archiso" image).
rm -f -- "${ROOT:?}"/etc/mkinitcpio.d/*.preset

# Live-only systemd units and every symlink that enables them.
live_units=(
    choose-mirror.service
    pacman-init.service
    livecd-talk.service
    livecd-alsa-unmuter.service
    etc-pacman.d-gnupg.mount
)
for unit in "${live_units[@]}"; do
    find "${ROOT}/etc/systemd/system" -name "${unit}" \( -type l -o -type f \) -delete
done

# Keep the Breeze SDDM theme that the removed autologin drop-in also set.
install -d -m 0755 -- "${ROOT}/etc/sddm.conf.d"
printf '[Theme]\nCurrent=breeze\n' >"${ROOT}/etc/sddm.conf.d/10-monos-theme.conf"

# --- 2. Kernels and mkinitcpio presets ----------------------------------------
log "restoring kernels in /boot"
install -d -m 0755 -- "${ROOT}/boot"
kernels=0
for pkgbase_file in "${ROOT}"/usr/lib/modules/*/pkgbase; do
    [[ -f "${pkgbase_file}" ]] || continue
    kdir="${pkgbase_file%/pkgbase}"
    pkgbase="$(<"${pkgbase_file}")"
    if [[ ! -f "${kdir}/vmlinuz" ]]; then
        log "warning: ${kdir}/vmlinuz missing, skipping ${pkgbase}"
        continue
    fi
    # The copy must NOT be sparse. mksquashfs stores the zero padding at the
    # end of the image as a hole, unpackfs keeps it, and a sparse-aware copy
    # (install/cp default) recreates it. On btrfs with NO_HOLES that tail is an
    # implicit hole, which GRUB's btrfs driver cannot read: it fails with
    # "premature end of file /@/boot/vmlinuz-linux".
    rm -f -- "${ROOT}/boot/vmlinuz-${pkgbase}"
    cp --sparse=never -- "${kdir}/vmlinuz" "${ROOT}/boot/vmlinuz-${pkgbase}"
    chmod 0644 -- "${ROOT}/boot/vmlinuz-${pkgbase}"
    sed "s|%PKGBASE%|${pkgbase}|g" "${ROOT}/usr/share/mkinitcpio/hook.preset" \
        | install -D -m 0644 /dev/stdin "${ROOT}/etc/mkinitcpio.d/${pkgbase}.preset"
    log "  ${pkgbase}: /boot/vmlinuz-${pkgbase} and /etc/mkinitcpio.d/${pkgbase}.preset"
    kernels=$((kernels + 1))
done
if ((kernels == 0)); then
    echo "error: no kernel found under ${ROOT}/usr/lib/modules" >&2
    exit 1
fi

# Microcode images are also removed from /boot. They are normally embedded in
# the initramfs by mkinitcpio's "microcode" hook; if mkarchiso had to ship
# separate images, restore them too (best effort).
for ucode in amd-ucode.img intel-ucode.img; do
    src="/run/archiso/bootmnt/monos/boot/${ucode}"
    if [[ -f "${src}" ]]; then
        install -m 0644 -- "${src}" "${ROOT}/boot/${ucode}"
    fi
done

# --- 3. pacman keyring --------------------------------------------------------
log "initializing the pacman keyring"
rm -rf -- "${ROOT:?}/etc/pacman.d/gnupg"
in_target pacman-key --init
in_target pacman-key --populate archlinux
# gpg-agent/dirmngr started inside the chroot would keep the target busy and
# make the final unmount fail.
in_target gpgconf --homedir /etc/pacman.d/gnupg --kill all || true

log "done"
