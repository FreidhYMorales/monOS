# monOS

monOS is an Arch Linux based, developer-focused distribution built with
[archiso](https://wiki.archlinux.org/title/Archiso). It boots into a KDE Plasma 6
(Wayland) live session as `liveuser` and ships a curated set of development and
command-line tools.

Current phase: bootable live ISO. The Calamares installer and custom artwork are
planned for a later phase.

## Requirements

On an Arch Linux host:

```sh
sudo pacman -S --needed archiso qemu-desktop edk2-ovmf
```

## Build

```sh
sudo ./build.sh
```

The profile is staged to `/var/tmp/monos-profile` and built in
`/var/tmp/monos-work` (both outside the project, whose path may contain spaces).
The ISO is written to `./out/`.

## Test

```sh
./test.sh          # UEFI boot in QEMU
./test.sh --bios   # legacy BIOS boot
```

Live credentials: `liveuser` / `monos` (passwordless `sudo`).

If the desktop does not start (for example GPU driver problems), pick the
"safe graphics, nomodeset" boot entry. If kitty fails to open in a VM without
3D acceleration, use `foot`.

## Structure

```text
.
├── build.sh              # builds the ISO (run with sudo)
├── test.sh               # boots the newest ISO in QEMU
└── profile/              # archiso profile (based on releng)
    ├── profiledef.sh     # ISO metadata and file permissions
    ├── packages.x86_64   # package list, grouped by purpose
    ├── pacman.conf
    ├── airootfs/         # files copied into the live root filesystem
    │   ├── etc/          # os-release, users, SDDM autologin, services, KDE defaults, skel
    │   └── home/liveuser # live user dotfiles
    ├── efiboot/          # systemd-boot entries (UEFI)
    ├── grub/             # GRUB menus
    └── syslinux/         # Syslinux menus (BIOS)
```
