# monOS

monOS is an Arch Linux based, developer-focused distribution built with
[archiso](https://wiki.archlinux.org/title/Archiso). It boots into a KDE Plasma 6
(Wayland) live session as `liveuser` and ships a curated set of development and
command-line tools.

Current phase: live medium that can be tried or installed (Fedora style) with the
Calamares installer. Custom artwork is planned for a later phase.

## Requirements

On an Arch Linux host:

```sh
sudo pacman -S --needed archiso qemu-desktop edk2-ovmf
```

## Build

The ISO needs a local pacman repository with the AUR packages (see
[Phase 2](#phase-2-installer)). Build it once, then the ISO:

```sh
./aur/build.sh     # as your normal user, NOT root
sudo ./build.sh
```

The profile is staged to `/var/tmp/monos-profile` and built in
`/var/tmp/monos-work` (both outside the project, whose path may contain spaces).
The ISO is written to `./out/`.

## Test

```sh
./test.sh                  # UEFI boot of the live ISO in QEMU
./test.sh --bios           # legacy BIOS boot of the live ISO
./test.sh --install        # live ISO + 40G virtual disk, to test the installer (UEFI)
./test.sh --install --bios # same, legacy BIOS
./test.sh --disk           # boot the installed virtual disk (UEFI)
./test.sh --disk --bios    # boot a disk that was installed with --install --bios
```

Live credentials: `liveuser` / `monos` (passwordless `sudo`).

If the desktop does not start (for example GPU driver problems), pick the
"safe graphics, nomodeset" boot entry. If kitty fails to open in a VM without
3D acceleration, use `foot`.

## Phase 2: installer

### 1. Build the AUR packages

`aur/build.sh` clones (or updates) the AUR packages listed in the
`AUR_PACKAGES` array at the top of the script into `~/.cache/monos-aur/` (outside the project: its path contains spaces), builds them with
`makepkg -s --noconfirm --needed`, copies the packages to `localrepo/x86_64/`
and updates the repository database `localrepo/x86_64/monos.db.tar.gz`.

| Package   | Why                                                    |
|-----------|--------------------------------------------------------|
| ckbcomp   | keyboard layout preview in Calamares (built first)     |
| calamares | the installer (patched, see below)                     |
| yay-bin   | optional AUR helper offered by the installer           |

Run it as your normal user. `-s` installs missing build dependencies with
`sudo pacman`, so it may ask for your password. If every build dependency is
already installed you can skip that with `MONOS_SYNCDEPS=0 ./aur/build.sh`.
You can also build a subset: `./aur/build.sh calamares`.

`aur/patches/calamares.patch` is applied to the AUR PKGBUILD before building:
it enables the `packagechooser` module (skipped upstream, needed for the "Install
yay?" page) and adds `python` to the dependencies (the Python job modules such as
`unpackfs`, `mount`, `bootloader` and `packages` are only built when the Python
headers are present). If the AUR package changes and the patch no longer
applies, the script stops: update the patch.

`localrepo/` and the AUR build directory are not committed. The repository will be published
as GitHub Releases assets later.

`build.sh` refuses to run without `localrepo/x86_64/monos.db.tar.gz`. It copies
`localrepo/` to `/var/tmp/monos-repo` and points the `[monos]` repository of
the staged `pacman.conf` at `file:///var/tmp/monos-repo/x86_64`. That
repository is only used to build the ISO: the live and installed systems get
`/etc/pacman.conf` from the `pacman` package (official repositories only).

### 2. Build and test an installation

```sh
sudo ./build.sh
./test.sh --install        # installs to /var/tmp/monos-disk.qcow2
```

In the live session, run **Install monOS** (desktop icon or application menu).
It starts Calamares as root (`/usr/local/bin/monos-install`). Without internet
the optional software page (netinstall) is hidden. After the installation, power
off the VM and boot the disk:

```sh
./test.sh --disk
```

Delete `/var/tmp/monos-disk.qcow2` and `/var/tmp/monos-OVMF_VARS.fd` to start
from a blank machine.

### What the installer does

- Pages: welcome, location, keyboard, partitions, AUR helper (yay), optional
  software (online only), users, summary.
- Partitions: btrfs (default) or ext4, optional LUKS encryption (LUKS1, so GRUB
  can unlock `/boot`), EFI system partition at `/boot/efi`, no swap partition
  (zram is used; a swap file can be chosen).
- btrfs subvolumes: `@` (/), `@home`, `@log` (/var/log), `@pkg`
  (/var/cache/pacman/pkg), `@snapshots` (/.snapshots), mounted with
  `noatime,compress=zstd`.
- The live root filesystem (`airootfs.sfs`) is copied to disk, then cleaned:
  live user, autologin, passwordless sudo, archiso initramfs settings and
  live-only services are removed; the pacman keyring is initialized.
- Kernels: mkarchiso leaves `/boot` of the live filesystem empty (kernels only
  exist on the ISO). The installer copies `/usr/lib/modules/<version>/vmlinuz`
  of every installed kernel (`linux`, `linux-lts`) to `/boot/vmlinuz-<pkgbase>`,
  recreates the standard mkinitcpio presets and runs `mkinitcpio -P`, exactly as
  pacman's mkinitcpio hook would.
- yay: kept by default; if you choose "Do not install yay" it is removed.
- Calamares, ckbcomp, mkinitcpio-archiso, archinstall and livecd-sounds are
  removed from the installed system.
- Boot loader: GRUB for UEFI (boot entry "monOS") and BIOS, with os-prober.
- Users: your user is in `wheel` (sudo with password) and `docker`; login shell
  zsh; SDDM without autologin unless you ask for it.

### Snapshots and rollback (btrfs)

- `snapper` has a `root` configuration for `/` (stored in `@snapshots`).
- `snap-pac` takes a *pre* and *post* snapshot around every pacman transaction,
  so each update or install can be undone.
- `snapper-timeline.timer` adds hourly snapshots (5 hourly and 7 daily kept);
  `snapper-cleanup.timer` prunes old ones.
- `grub-btrfsd` watches `/.snapshots` and adds a "monOS snapshots" submenu to
  GRUB. `/boot` lives inside `@`, so each snapshot contains matching kernel,
  initramfs and modules.

To roll back after a bad update:

1. Reboot and pick a snapshot from the GRUB snapshots submenu. It boots
   read-only with a temporary overlay in RAM (`grub-btrfs-overlayfs` hook), so
   you can check that it works.
2. Make it permanent. `/etc/fstab` mounts `subvol=/@` explicitly (flat layout),
   so `snapper rollback` (which changes the btrfs default subvolume) has no
   effect; replace `@` with a copy of the snapshot instead. From the booted
   snapshot (or the live ISO), with `N` = the snapshot number from `snapper list`:
   ```sh
   sudo mount -o subvolid=5 /dev/<root-partition-or-luks-mapper> /mnt
   sudo mv /mnt/@ /mnt/@.broken
   sudo btrfs subvolume snapshot /mnt/@snapshots/N/snapshot /mnt/@
   sudo umount /mnt && sudo reboot
   ```
   After checking the system, delete the old root:
   `sudo btrfs subvolume delete /mnt/@.broken` (with the top level mounted again).
   For small mistakes there is no need to reboot:
   `sudo snapper undochange <pre>..<post>` reverts the files changed between two
   snapshots (numbers from `snapper list`).

`/home`, `/var/log` and the package cache are separate subvolumes, so a rollback
never reverts your files or logs.

## Structure

```text
.
├── build.sh              # builds the ISO (run with sudo)
├── test.sh               # boots the newest ISO / the installed disk in QEMU
├── aur/
│   ├── build.sh          # builds AUR packages into localrepo/ (run as user)
│   └── patches/          # patches applied to AUR PKGBUILDs
├── branding/             # source artwork
├── localrepo/            # local pacman repo (generated, not committed)
└── profile/              # archiso profile (based on releng)
    ├── profiledef.sh     # ISO metadata and file permissions
    ├── packages.x86_64   # package list, grouped by purpose
    ├── pacman.conf
    ├── airootfs/         # files copied into the live root filesystem
    │   ├── etc/          # os-release, users, SDDM autologin, services, KDE defaults, skel
    │   ├── etc/calamares # installer settings, modules, branding, helper scripts
    │   ├── usr/local/    # installer launcher (monos-install) and menu entry
    │   └── home/liveuser # live user dotfiles
    ├── efiboot/          # systemd-boot entries (UEFI)
    ├── grub/             # GRUB menus
    └── syslinux/         # Syslinux menus (BIOS)
```
