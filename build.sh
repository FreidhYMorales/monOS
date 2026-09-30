#!/usr/bin/env bash
# Build the monOS live ISO with archiso.
#
# Usage: sudo ./build.sh
#
# Notes on paths:
# - The project directory may contain spaces (e.g. ".../SISTEMAS OPERATIVOS/PROYECTO 2"),
#   so every path below is quoted.
# - mkarchiso is not guaranteed to cope with spaces in the profile path, so the
#   profile is first copied to a space-free staging directory and built from there.
# - The work directory also lives outside the project (it needs several GiB and
#   must be on a filesystem that supports device nodes, not a mount with nodev).
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC_PROFILE="${SCRIPT_DIR}/profile"
STAGE_PROFILE="/var/tmp/monos-profile"
WORK="/var/tmp/monos-work"
OUT="${SCRIPT_DIR}/out"

if [[ "${EUID}" -ne 0 ]]; then
    echo "error: mkarchiso must run as root. Run: sudo ./build.sh" >&2
    exit 1
fi

if ! command -v mkarchiso >/dev/null 2>&1; then
    echo "error: mkarchiso not found. Install it with: sudo pacman -S archiso" >&2
    exit 1
fi

if [[ ! -f "${SRC_PROFILE}/profiledef.sh" ]]; then
    echo "error: profile not found at '${SRC_PROFILE}'" >&2
    exit 1
fi

echo ":: Cleaning previous work and staging directories"
rm -rf -- "${WORK}" "${STAGE_PROFILE}"

echo ":: Staging profile to '${STAGE_PROFILE}' (avoids spaces in the path)"
mkdir -p -- "${STAGE_PROFILE}"
# -a keeps symlinks (systemd unit enablement) and modes intact.
cp -a -- "${SRC_PROFILE}/." "${STAGE_PROFILE}/"

mkdir -p -- "${OUT}"

echo ":: Building ISO"
mkarchiso -v -w "${WORK}" -o "${OUT}" "${STAGE_PROFILE}"

# Give the ISO back to the invoking user so it can be used without root.
if [[ -n "${SUDO_UID:-}" && -n "${SUDO_GID:-}" ]]; then
    chown -R "${SUDO_UID}:${SUDO_GID}" -- "${OUT}"
fi

echo ":: Cleaning work and staging directories"
rm -rf -- "${WORK}" "${STAGE_PROFILE}"

echo ":: Done. ISO(s) in '${OUT}':"
ls -lh -- "${OUT}"/*.iso
