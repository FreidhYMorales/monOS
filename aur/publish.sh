#!/usr/bin/env bash
# Publish the local [monos] repository (localrepo/x86_64) to GitHub Releases.
#
# Usage: ./aur/publish.sh
#
# Installed monOS systems use it as an online pacman repository
# (/etc/pacman.conf, set by the 42-monos-pacman-conf build hook):
#   [monos]
#   Server = https://github.com/<owner>/<repo>/releases/download/repo
# pacman downloads <Server>/monos.db and <Server>/<package file>, so every
# file is a flat asset of the release tagged "repo". Assets are replaced
# (--clobber) and assets that are no longer in the local repository (old
# package versions) are deleted. Build the packages first: ./aur/build.sh
# Requires: gh (authenticated with write access to the repository).
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname -- "${SCRIPT_DIR}")/localrepo/x86_64"
TAG="repo"

if ! command -v gh >/dev/null 2>&1; then
    echo "error: 'gh' not found. Install it with: sudo pacman -S github-cli" >&2
    exit 1
fi
if [[ ! -f "${REPO_DIR}/monos.db.tar.gz" ]]; then
    echo "error: '${REPO_DIR}/monos.db.tar.gz' not found. Build the packages first: ./aur/build.sh" >&2
    exit 1
fi

# pacman asks for monos.db and monos.files: upload real copies under those
# names (the local ones are symlinks to the .tar.gz files).
STAGE="$(mktemp -d)"
trap 'rm -rf -- "${STAGE}"' EXIT
cp -L -- "${REPO_DIR}/monos.db" "${STAGE}/monos.db"
cp -L -- "${REPO_DIR}/monos.files" "${STAGE}/monos.files"

# Only the package files that the database references (repo-add -R already
# deletes replaced versions; this also skips stray files).
mapfile -t packages < <(tar -xOzf "${REPO_DIR}/monos.db.tar.gz" --wildcards '*/desc' |
    awk '/^%FILENAME%$/ { getline; print }')
files=("${STAGE}/monos.db" "${STAGE}/monos.files")
for pkg in "${packages[@]}"; do
    if [[ ! -f "${REPO_DIR}/${pkg}" ]]; then
        echo "error: '${pkg}' is in the database but missing from ${REPO_DIR}" >&2
        exit 1
    fi
    files+=("${REPO_DIR}/${pkg}")
done

if ! gh release view "${TAG}" >/dev/null 2>&1; then
    echo ":: Creating release '${TAG}'"
    gh release create "${TAG}" --title "monOS package repository" --latest=false \
        --notes "Prebuilt AUR packages for monOS (pacman repository [monos]). Updated by aur/publish.sh."
fi

echo ":: Uploading ${#files[@]} files to release '${TAG}'"
gh release upload "${TAG}" --clobber "${files[@]}"

# Delete assets that are no longer part of the repository.
declare -A wanted=()
for f in "${files[@]}"; do
    wanted["${f##*/}"]=1
done
while IFS= read -r asset; do
    if [[ -z "${wanted[${asset}]:-}" ]]; then
        echo "   deleting stale asset ${asset}"
        gh release delete-asset "${TAG}" "${asset}" --yes
    fi
done < <(gh release view "${TAG}" --json assets --jq '.assets[].name')

echo ":: Done: $(gh release view "${TAG}" --json url --jq .url)"
