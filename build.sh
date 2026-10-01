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
# Local pacman repository with the AUR packages (built by aur/build.sh).
SRC_REPO="${SCRIPT_DIR}/localrepo"
STAGE_REPO="/var/tmp/monos-repo"
REPO_DB_NAME="monos.db.tar.gz"

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

if [[ ! -f "${SRC_REPO}/x86_64/${REPO_DB_NAME}" ]]; then
    echo "error: local AUR repository not found ('${SRC_REPO}/x86_64/${REPO_DB_NAME}')." >&2
    echo "Build it first, as your normal user (not root): ./aur/build.sh" >&2
    exit 1
fi

# Packages that profile/packages.x86_64 takes from the [monos] repository.
repo_listing="$(tar -tzf "${SRC_REPO}/x86_64/${REPO_DB_NAME}")"
for pkg in calamares ckbcomp yay-bin yamis-icon-theme-git klassy bibata-cursor-theme-bin kwin-scripts-krohnkite; do
    if ! grep -qE "^${pkg}-[^-]+-[^-]+/$" <<<"${repo_listing}"; then
        echo "error: package '${pkg}' is missing from the local repository." >&2
        echo "Build it first, as your normal user (not root): ./aur/build.sh ${pkg}" >&2
        exit 1
    fi
done

echo ":: Cleaning previous work and staging directories"
rm -rf -- "${WORK}" "${STAGE_PROFILE}" "${STAGE_REPO}"

echo ":: Staging local repository to '${STAGE_REPO}'"
mkdir -p -- "${STAGE_REPO}"
cp -a -- "${SRC_REPO}/." "${STAGE_REPO}/"

echo ":: Staging profile to '${STAGE_PROFILE}' (avoids spaces in the path)"
mkdir -p -- "${STAGE_PROFILE}"
# -a keeps symlinks (systemd unit enablement) and modes intact.
cp -a -- "${SRC_PROFILE}/." "${STAGE_PROFILE}/"

# Point the [monos] repository of the staged pacman.conf at the staged repo.
# Only the build uses this file; it never ends up in the live/installed system.
sed -i -E '/^\[monos\]$/,/^\[/ s|^Server[[:space:]]*=.*$|Server = file://'"${STAGE_REPO}"'/x86_64|' \
    "${STAGE_PROFILE}/pacman.conf"
if ! grep -qxF "Server = file://${STAGE_REPO}/x86_64" "${STAGE_PROFILE}/pacman.conf"; then
    echo "error: could not set the [monos] Server line in '${STAGE_PROFILE}/pacman.conf'" >&2
    exit 1
fi

mkdir -p -- "${OUT}"

echo ":: Building ISO"
mkarchiso -v -w "${WORK}" -o "${OUT}" "${STAGE_PROFILE}"

# Give the ISO back to the invoking user so it can be used without root.
if [[ -n "${SUDO_UID:-}" && -n "${SUDO_GID:-}" ]]; then
    chown -R "${SUDO_UID}:${SUDO_GID}" -- "${OUT}"
fi

echo ":: Cleaning work and staging directories"
rm -rf -- "${WORK}" "${STAGE_PROFILE}" "${STAGE_REPO}"

echo ":: Done. ISO(s) in '${OUT}':"
ls -lh -- "${OUT}"/*.iso
