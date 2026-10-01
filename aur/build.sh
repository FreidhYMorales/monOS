#!/usr/bin/env bash
# Build the AUR packages monOS ships and publish them in a local pacman
# repository (localrepo/x86_64/monos.db.tar.gz) that build.sh feeds to mkarchiso.
#
# Usage: ./aur/build.sh [package ...]
#
#   Run as a NORMAL user (makepkg refuses to run as root). makepkg is called
#   with -s, which installs missing build dependencies through `sudo pacman`,
#   so you will be asked for your sudo password when something is missing.
#   Set MONOS_SYNCDEPS=0 to drop -s when all build dependencies are installed.
#
#   Without arguments every package in AUR_PACKAGES is built, in order.
#
# Patches: if aur/patches/<package>.patch exists it is applied (git apply) to
# the freshly reset AUR checkout before building. A patch that no longer
# applies aborts the build on purpose: review the upstream change first.
set -euo pipefail

# Build order matters: AUR dependencies must come before the packages that
# need them. ckbcomp is used by Calamares' keyboard page (layout preview).
# None of the theming packages depends on another AUR package. klassy is
# built from source (its PKGBUILD also produces klassy-qt5, which is not
# installed on the ISO).
# plasma6-applets-panel-colorizer compiles a small C++ QML plugin: its build
# needs libplasma (and cmake/extra-cmake-modules), which makepkg -s installs.
# plasma6-applets-kara (top bar virtual desktops) also compiles a C++ QML
# plugin, against kwin, plasma-workspace (libtaskmanager) and libplasma.
# plasma6-applets-window-title is plain QML (no build step); makepkg still
# wants its runtime dependency, plasma-workspace, on the build host.
AUR_PACKAGES=(
    ckbcomp
    calamares
    yay-bin
    yamis-icon-theme-git
    klassy
    bibata-cursor-theme-bin
    kwin-scripts-krohnkite
    plasma6-applets-panel-colorizer
    plasma6-applets-kara
    plasma6-applets-window-title
)

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname -- "${SCRIPT_DIR}")"
# Build outside the project: its path contains spaces, which break compiler
# flags such as makepkg's -ffile-prefix-map (debug option).
SRC_DIR="${MONOS_AUR_SRC:-${XDG_CACHE_HOME:-${HOME}/.cache}/monos-aur}"
PATCH_DIR="${SCRIPT_DIR}/patches"
REPO_DIR="${PROJECT_DIR}/localrepo/x86_64"
REPO_DB="${REPO_DIR}/monos.db.tar.gz"
AUR_URL="https://aur.archlinux.org"

if [[ "${EUID}" -eq 0 ]]; then
    echo "error: do not run this script as root; makepkg refuses to build as root." >&2
    echo "Run it as your normal user: ./aur/build.sh" >&2
    exit 1
fi

if [[ "${SRC_DIR}" == *[[:space:]]* ]]; then
    echo "error: build directory '${SRC_DIR}' contains spaces; set MONOS_AUR_SRC to a path without spaces." >&2
    exit 1
fi

for tool in git makepkg repo-add; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
        echo "error: '${tool}' not found. Install it with: sudo pacman -S --needed base-devel git pacman-contrib" >&2
        exit 1
    fi
done

makepkg_flags=(--noconfirm --needed)
if [[ "${MONOS_SYNCDEPS:-1}" != "0" ]]; then
    makepkg_flags=(-s "${makepkg_flags[@]}")
fi

if (($#)); then
    packages=("$@")
else
    packages=("${AUR_PACKAGES[@]}")
fi

mkdir -p -- "${SRC_DIR}" "${REPO_DIR}"

# makepkg exit code when the package file already exists (makepkg's E_ALREADY_BUILT).
readonly E_ALREADY_BUILT=13

fetch_package() {
    local pkg="$1" dir="${SRC_DIR}/$1"
    if [[ -d "${dir}/.git" ]]; then
        echo ":: Updating '${pkg}' from the AUR"
        git -C "${dir}" fetch --quiet origin
        # Hard reset so local patches from a previous run never block the update.
        git -C "${dir}" reset --quiet --hard '@{upstream}'
    else
        echo ":: Cloning '${pkg}' from the AUR"
        git clone --quiet -- "${AUR_URL}/${pkg}.git" "${dir}"
    fi
    if [[ ! -f "${dir}/PKGBUILD" ]]; then
        echo "error: '${pkg}' has no PKGBUILD (does the AUR package exist?)" >&2
        exit 1
    fi
    if [[ -f "${PATCH_DIR}/${pkg}.patch" ]]; then
        echo "   applying ${PATCH_DIR##*/}/${pkg}.patch"
        git -C "${dir}" apply "${PATCH_DIR}/${pkg}.patch"
    fi
}

# True when every (non-debug) package file of the current PKGBUILD version exists.
all_built() {
    local dir="$1" file found=0
    while IFS= read -r file; do
        [[ "${file##*/}" == *-debug-* ]] && continue
        [[ -f "${file}" ]] || return 1
        found=1
    done < <(cd -- "${dir}" && makepkg --packagelist)
    ((found))
}

build_package() {
    local pkg="$1" dir="${SRC_DIR}/$1" rc=0
    echo ":: Building '${pkg}'"
    if all_built "${dir}"; then
        echo "   already built, reusing it"
    else
        (cd -- "${dir}" && makepkg "${makepkg_flags[@]}") || rc=$?
    fi
    if ((rc != 0 && rc != E_ALREADY_BUILT)); then
        echo "error: makepkg failed for '${pkg}' (exit code ${rc})" >&2
        exit "${rc}"
    fi

    # Copy exactly the files this PKGBUILD produces (current version only).
    local -a built=()
    mapfile -t built < <(cd -- "${dir}" && makepkg --packagelist)
    local file
    for file in "${built[@]}"; do
        # --packagelist also lists <pkg>-debug when makepkg.conf enables the
        # "debug" option, even for packages that produce no debug package.
        # Debug packages are not needed on the ISO.
        if [[ "${file##*/}" == *-debug-* ]]; then
            continue
        fi
        if [[ ! -f "${file}" ]]; then
            echo "error: expected package file '${file}' was not built" >&2
            exit 1
        fi
        cp -f -- "${file}" "${REPO_DIR}/"
        new_files+=("${REPO_DIR}/${file##*/}")
    done
}

new_files=()
for pkg in "${packages[@]}"; do
    fetch_package "${pkg}"
    build_package "${pkg}"
done

echo ":: Updating repository database '${REPO_DB}'"
# -R removes the previous package file of the same package from disk.
repo-add -R -- "${REPO_DB}" "${new_files[@]}"

echo ":: Done. Repository contents:"
ls -lh -- "${REPO_DIR}"
