#!/usr/bin/env bash
# monOS installer: keep only the optional AI tools selected in the installer.
#
# Usage (Calamares shellprocess@ai, dontChroot):
#   monos-ai-tools.sh <target-root> sel:<comma-separated item ids>
#
# Every optional AI tool is installed on the live system, so the copied target
# has all of them; this removes (pacman -Rns) the packages of the tools that
# were not selected. Item ids come from modules/packagechooser_ai.conf.
set -euo pipefail

ROOT="${1:-}"
SELECTION="${2:-}"
if [[ -z "${ROOT}" || "${ROOT}" == "/" || ! -d "${ROOT}/etc" || "${SELECTION}" != sel:* ]]; then
    echo "error: usage: $0 <target-root> sel:<ids> (got '${ROOT}' '${SELECTION}')" >&2
    exit 1
fi

log() { printf 'monos-ai-tools: %s\n' "$*"; }

declare -A packages=(
    [claude]="claude-code"
    [antigravity]="antigravity-ide"
    [herdr]="herdr-bin"
)

IFS=',' read -r -a selected <<<"${SELECTION#sel:}"
declare -A keep=()
for id in "${selected[@]}"; do
    [[ -n "${id}" ]] && keep["${id}"]=1
done

remove=()
for id in "${!packages[@]}"; do
    if [[ -n "${keep[${id}]:-}" ]]; then
        log "keeping ${id} (${packages[${id}]})"
        continue
    fi
    for pkg in ${packages[${id}]}; do
        if chroot "${ROOT}" pacman -Qq "${pkg}" >/dev/null 2>&1; then
            remove+=("${pkg}")
        fi
    done
done

if ((${#remove[@]} == 0)); then
    log "nothing to remove"
    exit 0
fi
log "removing ${remove[*]}"
chroot "${ROOT}" pacman -Rns --noconfirm "${remove[@]}"
