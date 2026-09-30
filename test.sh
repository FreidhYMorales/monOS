#!/usr/bin/env bash
# Boot the most recent monOS ISO in QEMU using archiso's run_archiso helper.
#
# Usage: ./test.sh           # UEFI boot (default)
#        ./test.sh --bios    # legacy BIOS boot
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OUT="${SCRIPT_DIR}/out"

mode="uefi"
case "${1:-}" in
    "") ;;
    --bios) mode="bios" ;;
    --uefi) mode="uefi" ;;
    -h|--help)
        echo "Usage: $0 [--bios|--uefi]"
        exit 0
        ;;
    *)
        echo "error: unknown option '$1'. Usage: $0 [--bios|--uefi]" >&2
        exit 1
        ;;
esac

missing=()
for pkg in qemu-desktop edk2-ovmf; do
    pacman -Qq "${pkg}" >/dev/null 2>&1 || missing+=("${pkg}")
done
if ((${#missing[@]})); then
    echo "error: missing packages: ${missing[*]}" >&2
    echo "Install them with: sudo pacman -S --needed ${missing[*]}" >&2
    exit 1
fi

if ! command -v run_archiso >/dev/null 2>&1; then
    echo "error: run_archiso not found. Install it with: sudo pacman -S archiso" >&2
    exit 1
fi

shopt -s nullglob
isos=("${OUT}"/*.iso)
shopt -u nullglob
if ((${#isos[@]} == 0)); then
    echo "error: no ISO found in '${OUT}'. Build one first: sudo ./build.sh" >&2
    exit 1
fi

# Pick the newest ISO by modification time.
latest="${isos[0]}"
for iso in "${isos[@]}"; do
    [[ "${iso}" -nt "${latest}" ]] && latest="${iso}"
done

echo ":: Booting '${latest}' (${mode})"
if [[ "${mode}" == "uefi" ]]; then
    exec run_archiso -u -i "${latest}"
else
    exec run_archiso -b -i "${latest}"
fi
