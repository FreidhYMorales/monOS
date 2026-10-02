#!/usr/bin/env bash
# Boot monOS in QEMU.
#
# Usage: ./test.sh [--uefi|--bios]             # live ISO only (archiso's run_archiso)
#        ./test.sh --install [--uefi|--bios]   # live ISO + virtual disk, to test the installer
#        ./test.sh --disk [--uefi|--bios]      # boot the installed virtual disk (no ISO)
#        ./test.sh --install --usb             # install into a raw image meant for a USB drive
#        ./test.sh --disk --usb                # boot that image
#
# Firmware defaults to UEFI. A system installed with --bios must be booted
# with --disk --bios (and a UEFI install with --disk / --disk --uefi).
#
# Virtual disk: /var/tmp/monos-disk.qcow2 (40G, created on first --install).
# UEFI variables: /var/tmp/monos-OVMF_VARS.fd (writable copy, keeps the
# "monOS" boot entry created by the installer). Delete both to start over.
#
# --usb uses a raw image (/var/tmp/monos-usb.img, 24G) instead of the qcow2
# disk, to put an installed monOS on a USB drive. Installing straight onto a
# cheap USB stick through QEMU is impractically slow (unpacking ~200k small
# files is random I/O) and stalls QEMU. Install into the image at NVMe speed,
# then write it sequentially, skipping unused (zero) blocks:
#   sudo dd if=/var/tmp/monos-usb.img of=/dev/sdX bs=4M conv=sparse,fsync status=progress
#   sudo sgdisk -e /dev/sdX   # move the backup GPT header to the end of the drive
# The installer writes GRUB to the removable-media path (EFI/BOOT/BOOTX64.EFI),
# so the drive boots on real UEFI machines. monos-hardware-cleanup.sh runs
# inside the VM: it removes the NVIDIA driver and keeps the QEMU guest tools.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OUT="${SCRIPT_DIR}/out"

DISK="/var/tmp/monos-disk.qcow2"
DISK_SIZE="40G"
OVMF_CODE="/usr/share/edk2/x64/OVMF_CODE.4m.fd"
OVMF_VARS_TEMPLATE="/usr/share/edk2/x64/OVMF_VARS.4m.fd"
OVMF_VARS="/var/tmp/monos-OVMF_VARS.fd"
usb=0

usage() {
    echo "Usage: $0 [--install|--disk] [--uefi|--bios] [--usb]"
}

mode="live"
firmware="uefi"
for arg in "$@"; do
    case "${arg}" in
        --bios) firmware="bios" ;;
        --uefi) firmware="uefi" ;;
        --install) mode="install" ;;
        --disk) mode="disk" ;;
        --usb) usb=1 ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "error: unknown option '${arg}'. $(usage)" >&2
            exit 1
            ;;
    esac
done

missing=()
for pkg in qemu-desktop edk2-ovmf; do
    pacman -Qq "${pkg}" >/dev/null 2>&1 || missing+=("${pkg}")
done
if ((${#missing[@]})); then
    echo "error: missing packages: ${missing[*]}" >&2
    echo "Install them with: sudo pacman -S --needed ${missing[*]}" >&2
    exit 1
fi

find_latest_iso() {
    local -a isos
    shopt -s nullglob
    isos=("${OUT}"/*.iso)
    shopt -u nullglob
    if ((${#isos[@]} == 0)); then
        echo "error: no ISO found in '${OUT}'. Build one first: sudo ./build.sh" >&2
        exit 1
    fi
    # Pick the newest ISO by modification time.
    local latest="${isos[0]}" iso
    for iso in "${isos[@]}"; do
        [[ "${iso}" -nt "${latest}" ]] && latest="${iso}"
    done
    printf '%s\n' "${latest}"
}

# --- Live ISO only: keep using archiso's helper -------------------------------
if [[ "${mode}" == "live" ]]; then
    if ! command -v run_archiso >/dev/null 2>&1; then
        echo "error: run_archiso not found. Install it with: sudo pacman -S archiso" >&2
        exit 1
    fi
    latest="$(find_latest_iso)"
    echo ":: Booting '${latest}' (${firmware})"
    if [[ "${firmware}" == "uefi" ]]; then
        exec run_archiso -u -i "${latest}"
    else
        exec run_archiso -b -i "${latest}"
    fi
fi

# --- Install / disk modes: plain qemu-system-x86_64 --------------------------
if ((usb)); then
    DISK="/var/tmp/monos-usb.img"
    DISK_SIZE="24G"
    DISK_FORMAT="raw"
    OVMF_VARS="/var/tmp/monos-OVMF_VARS-usb.fd"
else
    DISK_FORMAT="qcow2"
fi

if [[ ! -r /dev/kvm ]]; then
    echo "error: /dev/kvm is not available (enable virtualization / load kvm modules)" >&2
    exit 1
fi

qemu_args=(
    -name "monOS (${mode} - ${firmware})"
    -machine q35,accel=kvm
    -cpu host
    -smp 4
    -m 6G
    -vga virtio
    -display gtk
    -device virtio-net-pci,netdev=net0
    -netdev user,id=net0
    -device intel-hda -device hda-output
    -device qemu-xhci -device usb-tablet
    -drive "file=${DISK},if=virtio,format=${DISK_FORMAT},cache=writeback,discard=unmap"
)

if [[ "${firmware}" == "uefi" ]]; then
    for f in "${OVMF_CODE}" "${OVMF_VARS_TEMPLATE}"; do
        if [[ ! -f "${f}" ]]; then
            echo "error: OVMF firmware file '${f}' not found (package edk2-ovmf)" >&2
            exit 1
        fi
    done
    if [[ ! -f "${OVMF_VARS}" ]]; then
        cp -- "${OVMF_VARS_TEMPLATE}" "${OVMF_VARS}"
    fi
    qemu_args+=(
        -drive "if=pflash,format=raw,unit=0,file=${OVMF_CODE},readonly=on"
        -drive "if=pflash,format=raw,unit=1,file=${OVMF_VARS}"
    )
fi

if [[ "${mode}" == "install" ]]; then
    if [[ ! -f "${DISK}" ]]; then
        echo ":: Creating virtual disk '${DISK}' (${DISK_SIZE})"
        qemu-img create -f "${DISK_FORMAT}" "${DISK}" "${DISK_SIZE}"
    fi
    latest="$(find_latest_iso)"
    echo ":: Booting '${latest}' with disk '${DISK}' (${firmware})"
    # The ISO boots first; the disk is used once the ISO is removed (--disk).
    qemu_args+=(
        -drive "file=${latest},media=cdrom,readonly=on,if=none,id=cd0"
        -device ide-cd,drive=cd0,bootindex=0
    )
else
    if [[ ! -f "${DISK}" ]]; then
        echo "error: '${DISK}' does not exist. Install monOS first: ./test.sh --install" >&2
        exit 1
    fi
    echo ":: Booting installed disk '${DISK}' (${firmware})"
fi

exec qemu-system-x86_64 "${qemu_args[@]}"
