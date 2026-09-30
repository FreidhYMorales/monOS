#!/usr/bin/env bash
# monOS installer: snapper configuration for a btrfs root.
#
# Usage (Calamares shellprocess@snapper, dontChroot): monos-snapper-setup.sh <target-root>
#
# The mount module already mounted the @snapshots subvolume at /.snapshots,
# but `snapper create-config` refuses to run when /.snapshots exists (it wants
# to create a nested .snapshots subvolume itself). Standard workaround:
#   1. unmount @snapshots and remove the empty mount point,
#   2. snapper -c root create-config /  (creates @/.snapshots + config),
#   3. delete that nested subvolume and recreate the directory,
#   4. mount @snapshots again (fstab already has the entry).
# Then tune the limits and enable snapper-timeline.timer,
# snapper-cleanup.timer and grub-btrfsd.service (snapshots menu in GRUB).
# snap-pac (already installed) creates pre/post snapshots on every pacman
# transaction once the "root" config exists.
#
# On a non-btrfs root nothing is done.
set -euo pipefail

ROOT="${1:-}"
if [[ -z "${ROOT}" || "${ROOT}" == "/" || ! -d "${ROOT}/etc" ]]; then
    echo "error: usage: $0 <target-root> (got '${ROOT}')" >&2
    exit 1
fi

log() { printf 'monos-snapper: %s\n' "$*"; }
in_target() { chroot "${ROOT}" "$@"; }

fstype="$(findmnt -n -o FSTYPE --mountpoint "${ROOT}" || true)"
if [[ "${fstype}" != "btrfs" ]]; then
    log "root filesystem is '${fstype:-unknown}', not btrfs: skipping snapper setup"
    exit 0
fi

snapdir="${ROOT}/.snapshots"
if ! mountpoint -q -- "${snapdir}"; then
    echo "error: ${snapdir} is not mounted (expected the @snapshots subvolume)" >&2
    exit 1
fi

# e.g. SOURCE="/dev/mapper/luks-...[/@snapshots]" OPTIONS="rw,noatime,compress=zstd:3,...,subvol=/@snapshots"
snap_source="$(findmnt -n -o SOURCE --mountpoint "${snapdir}")"
snap_device="${snap_source%%\[*}"
snap_options="$(findmnt -n -o OPTIONS --mountpoint "${snapdir}")"

log "creating snapper config 'root'"
umount "${snapdir}"
rmdir -- "${snapdir}"
in_target snapper --no-dbus -c root create-config /
btrfs subvolume delete -- "${snapdir}"
mkdir -- "${snapdir}"
mount -o "${snap_options}" "${snap_device}" "${snapdir}"
chmod 0750 -- "${snapdir}"

config="${ROOT}/etc/snapper/configs/root"
set_config() {
    local key="$1" value="$2"
    if grep -q "^${key}=" "${config}"; then
        sed -i "s|^${key}=.*|${key}=\"${value}\"|" "${config}"
    else
        printf '%s="%s"\n' "${key}" "${value}" >>"${config}"
    fi
}
# Members of wheel may list/compare snapshots without sudo.
set_config ALLOW_GROUPS "wheel"
# Keep a modest number of snapshots (pacman pre/post pairs + timeline).
set_config NUMBER_LIMIT "20"
set_config NUMBER_LIMIT_IMPORTANT "10"
set_config TIMELINE_CREATE "yes"
set_config TIMELINE_LIMIT_HOURLY "5"
set_config TIMELINE_LIMIT_DAILY "7"
set_config TIMELINE_LIMIT_WEEKLY "0"
set_config TIMELINE_LIMIT_MONTHLY "0"
set_config TIMELINE_LIMIT_YEARLY "0"

log "enabling snapper timers and grub-btrfsd"
in_target systemctl enable snapper-timeline.timer snapper-cleanup.timer grub-btrfsd.service

log "done"
