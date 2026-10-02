# monOS

**Website:** https://monos-os.vercel.app · **Download (ISO):** [Google Drive](https://drive.google.com/drive/folders/1nUSszLPcizV07Xjbe--AbGI46P8qUbDi?usp=sharing)

monOS is an Arch Linux based, developer-focused distribution built with
[archiso](https://wiki.archlinux.org/title/Archiso). It boots into a KDE Plasma 6
(Wayland) live session as `liveuser` and ships a curated set of development and
command-line tools.

Current phase: live medium that can be tried or installed (Fedora style) with the
Calamares installer, with the monOS look (palette, desktop, boot splash, boot
menus) applied to the live and the installed system.

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

| Package                 | Why                                                         |
|-------------------------|-------------------------------------------------------------|
| ckbcomp                 | keyboard layout preview in Calamares (built first)          |
| calamares               | the installer (patched, see below)                          |
| yay-bin                 | optional AUR helper offered by the installer                |
| yamis-icon-theme-git    | Yamis monochrome icons (Global Theme icon theme)            |
| klassy                  | application style and window decoration (built from source) |
| bibata-cursor-theme-bin | Bibata cursors (upstream release archive)                   |
| kwin-scripts-krohnkite  | Krohnkite dynamic tiling KWin script (patched, see below)   |
| plasma6-applets-panel-colorizer | Panel Colorizer: top bar islands and dock surface (third-party) |
| plasma6-applets-kara    | Kara: GNOME-style virtual desktop switcher in the top bar (third-party) |
| plasma6-applets-window-title | Window Title: active window icon and name in the top bar (third-party) |

`klassy` is built from source rather than `klassy-bin`: the source package
compiles against the Plasma/KDecoration version installed on the build host,
while `klassy-bin` repackages a prebuilt openSUSE OBS binary without checksums
that can lag behind a Plasma update (KDecoration plugins break on ABI
changes). Its build dependencies (`extra-cmake-modules`, KF6 and KF5
development packages) are installed by `makepkg -s`. The PKGBUILD also
produces `klassy-qt5` (Qt5 style); it lands in `localrepo/` but is not
installed on the ISO.

`plasma6-applets-panel-colorizer` also compiles a small C++ QML plugin
(used for the blur behind the islands): its build needs `libplasma`,
`cmake` and `extra-cmake-modules`, installed by `makepkg -s`.

`plasma6-applets-kara` is the stable package (pinned to the upstream `v1.0.0`
tag) rather than `plasma6-applets-kara-git`, which builds whatever upstream
HEAD is at build time. It also compiles a C++ QML plugin, linked against
`kwin`, `plasma-workspace` (libtaskmanager) and `libplasma`: those build
dependencies are installed by `makepkg -s`, and like Klassy it should be
rebuilt after a Plasma update.

`plasma6-applets-window-title` is plain QML (release tarball with a
checksum, no build step), but makepkg checks its runtime dependency
`plasma-workspace`, so the build host needs it installed (`makepkg -s` does
that).

Run it as your normal user. `-s` installs missing build dependencies with
`sudo pacman`, so it may ask for your password. If every build dependency is
already installed you can skip that with `MONOS_SYNCDEPS=0 ./aur/build.sh`.
You can also build a subset: `./aur/build.sh calamares`.

`aur/patches/kwin-scripts-krohnkite.patch` takes Krohnkite's LICENSE from the
git commit of the release tag instead of the Codeberg archive tarball, whose
checksum changed upstream (the `.kwinscript` itself is still verified).

`aur/patches/calamares.patch` is applied to the AUR PKGBUILD before building:
it enables the `packagechooser` module (skipped upstream, needed for the "Install
yay?" page) and adds `python` to the dependencies (the Python job modules such as
`unpackfs`, `mount`, `bootloader` and `packages` are only built when the Python
headers are present). If the AUR package changes and the patch no longer
applies, the script stops: update the patch.

`localrepo/` and the AUR build directory are not committed.

`build.sh` refuses to run without `localrepo/x86_64/monos.db.tar.gz`. It copies
`localrepo/` to `/var/tmp/monos-repo` and points the `[monos]` repository of
the staged `pacman.conf` at `file:///var/tmp/monos-repo/x86_64`. That copy is
only used to build the ISO.

#### Online `[monos]` repository

The same packages are published as a pacman repository on GitHub Releases
(release tag `repo`), so AUR tools that are too big or too niche for the ISO
(Claude Code, Google Antigravity, herdr, Android Studio, Flutter, Postman,
Bruno, Google Cloud CLI) are offered by the installer's netinstall groups and
downloaded at install time:

```bash
./aur/build.sh      # build or update every package in AUR_PACKAGES
./aur/publish.sh    # upload localrepo/x86_64 to the "repo" release (needs gh)
```

The live and installed systems get it from the `42-monos-pacman-conf` build
hook, which appends to `/etc/pacman.conf`:

```ini
[monos]
SigLevel = Optional TrustAll
Server = https://github.com/FreidhYMorales/monOS/releases/download/repo
```

It comes after `[extra]`, so an official package wins on a name clash. The
packages are not signed. Updates reach users through `pacman -Syu` after the
next `./aur/build.sh && ./aur/publish.sh`; until then they lag behind the
AUR.

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
  removed from the installed system, together with live-medium tools (see
  [Hardware, drivers and services](#hardware-drivers-and-services)).
- Drivers and VM guest tools the machine does not need are removed
  (NVIDIA, thermald, intel-media-driver, guest tools).
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

## Hardware, drivers and services

### Packages

`profile/packages.x86_64` is grouped by purpose. Besides the base system and
Plasma it ships:

| Group | Packages |
|-------|----------|
| KDE essentials | dolphin-plugins, kio-extras, kdegraphics-thumbnailers, ffmpegthumbs, kio-admin, kdeplasma-addons, kdeconnect, partitionmanager, kcalc, plasma-browser-integration |
| System | fwupd (firmware updates in Discover), ufw + plasma-firewall, cups + print-manager |
| Development | git-lfs, gdb, just, shellcheck, uv, mise (plus the existing toolchains) |
| Fonts | noto-fonts-cjk, ttf-liberation |
| Multimedia | gst-plugin-pipewire, gst-libav |
| Drivers | intel-media-driver, thermald, nvidia-open, nvidia-open-lts, nvidia-utils, libva-nvidia-driver |
| Applications | obsidian |
| Containers | docker + docker-compose, podman + distrobox (see [Containers](#containers)) |
| Snapshots | snapper, snap-pac, grub-btrfs, btrfs-assistant (GUI: subvolumes, Snapper snapshots, balance/scrub) |
| Dolphin terminal panel | konsole (only for the F4 panel, see below) |

Not included: `cups-pdf` (the Qt, GTK and Firefox print dialogs already print
to PDF), `system-config-printer` (print-manager is the KDE tool),
`nvidia-settings` (mostly X11 settings; `nvidia-smi` covers monitoring on
Wayland) and 32-bit NVIDIA libraries (no multilib).

Dolphin's terminal panel (F4) embeds Konsole's KPart (`konsolepart`, shipped
only in the `konsole` package) and cannot use another terminal, so Konsole is
installed but hidden: `/usr/local/share/applications/org.kde.konsole.desktop`
overrides its launcher with `NoDisplay=true`, and its Ctrl+Alt+T shortcut is
given to kitty (`/etc/skel/.config/kglobalshortcutsrc`). kitty stays the
default terminal (`TerminalApplication` in `/etc/xdg/kdeglobals`).

Flatpak: Arch's `flatpak` package already ships
`/usr/share/flatpak/remotes.d/flathub.flatpakrepo`, which flatpak adds as the
system-wide `flathub` remote on first use, so Discover lists Flathub
applications without any setup (installing them needs internet access).

pacman (`/etc/pacman.conf`, set at build time by the pacman hook
`42-monos-pacman-conf.hook` because the file belongs to the pacman package):
`ParallelDownloads = 10`, `Color`, `VerbosePkgLists` and `ILoveCandy`.

### Containers

Docker (socket-activated, your user is in `docker`) and rootless Podman are
both installed; they do not conflict. `distrobox` runs other distributions'
userlands in containers that share your home directory (`distrobox create -i
ubuntu:24.04`, then `distrobox enter`); it uses Podman when both are present.
Rootless Podman needs subordinate user/group ID ranges: the installer creates
your user with `useradd`, which adds them to `/etc/subuid` and `/etc/subgid`
(`SUB_UID_*`/`SUB_GID_*` in `/etc/login.defs`); on the live session `liveuser`
gets them from the pacman hook `42-monos-liveuser-subids.hook`. For users
created otherwise, run `sudo usermod --add-subuids 100000-165535
--add-subgids 100000-165535 <user>` (with a free range) and `podman system migrate`.

### NVIDIA

monOS ships the NVIDIA **open** kernel modules (`nvidia-open` for `linux`,
`nvidia-open-lts` for `linux-lts`). Since driver 590 NVIDIA only supports
Turing (GTX 16xx, RTX 20xx) and newer GPUs, which is exactly what the open
modules support. No extra configuration is needed: `nvidia-drm` enables
`modeset` and `fbdev` by default, and nvidia-utils blacklists `nouveau`
(and `nova`) through `/usr/lib/modprobe.d/nvidia-utils.conf`. The modules
are loaded after the initramfs (no early KMS), so the boot splash uses the
firmware framebuffer and the desktop the NVIDIA driver.

Older NVIDIA GPUs (Maxwell, Pascal, Volta and earlier) need `nouveau`, which
that blacklist would disable. The live session therefore decides per machine,
with no extra boot entry:

- At ISO build time the pacman hook `41-monos-nvidia-live.hook` writes
  `/etc/modprobe.d/nvidia-utils.conf`, a copy of nvidia-utils' file without
  `blacklist nouveau` (a file with the same name in `/etc` replaces the one
  in `/usr/lib`).
- `/etc/modprobe.d/monos-nouveau-gate.conf` routes every `nouveau` load
  through `/usr/local/lib/monos/nouveau-gate`, which loads nouveau only when
  no GPU is supported by nvidia-open (or the nvidia module is missing).
- Detection (`/usr/local/lib/monos/nvidia-open-supported`): NVIDIA display
  controllers (PCI vendor `10de`, class `03xx`) from `/sys/bus/pci/devices`,
  compared with the "Current NVIDIA GPUs" table of the README shipped by
  nvidia-utils (`/usr/share/doc/nvidia/html/supportedchips.html`); without
  it, device ID >= `0x1E00` (first Turing ID).
- To force nouveau on a supported GPU, add `module_blacklist=nvidia` to the
  kernel command line. If the desktop does not start at all, use the
  "safe graphics, nomodeset" entry.

The installed system does not keep that gate: it uses the stock nvidia-utils
configuration, or no NVIDIA packages at all (below).

### Installer hardware cleanup

`/etc/calamares/scripts/monos-hardware-cleanup.sh` (`shellprocess@hardware`,
right after the general cleanup and before the packages module and
`initcpio`) detects the hardware on the live system and removes from the
target what it does not need, in one pacman transaction (`-Rns`, with
mkinitcpio's pacman hook masked; the `initcpio` module rebuilds the
initramfs afterwards):

| Condition | Removed |
|-----------|---------|
| no NVIDIA GPU, or only pre-Turing ones | nvidia-open, nvidia-open-lts, nvidia-utils, libva-nvidia-driver |
| CPU is not Intel | thermald (disabled first) |
| no Intel GPU | intel-media-driver |
| bare metal (`systemd-detect-virt --vm` = none) | open-vm-tools, qemu-guest-agent, virtualbox-guest-utils-nox, hyperv (units disabled first) |
| VMware / KVM-QEMU / VirtualBox / Hyper-V | the guest tools of the other hypervisors |

An unknown hypervisor keeps every guest tool; if NVIDIA detection fails the
driver is kept.

The packages module (`modules/packages.conf`, `try_remove`, i.e. `pacman -Rs`
per package, which never removes explicitly installed or still-required
packages) removes live-medium tools: clonezilla, partclone, partimage,
fsarchiver (imaging/rescue), irssi, lynx, darkhttpd (install guide and PXE
helpers), mc (yazi covers it), xl2tpd, pptpclient, wvdial (legacy dial-up
and VPN), espeakup and brltty (speech/braille boot; brltty also claims
CH340/CH341 USB-serial adapters), memtest86+, memtest86+-efi, edk2-shell,
refind and syslinux (they only boot the ISO; GRUB boots the installed
system). Kept on purpose: ddrescue, testdisk, nmap, tcpdump, rsync, openssh,
openvpn, openconnect (with vpnc, which it needs), smartmontools, nvme-cli and
mkinitcpio-nfs-utils (removing it would rebuild every initramfs once more).

### Services

| Unit | Live | Installed | Notes |
|------|------|-----------|-------|
| `cups.socket` | yes | yes | printing, started on demand |
| `NetworkManager-wait-online.service` | no | no | disabled: nothing at boot needs `network-online.target`, and when something pulls that target in, it waits up to 60 s for a connection; Calamares disables it again after enabling NetworkManager (whose `[Install]` has `Also=NetworkManager-wait-online.service`) |
| `reflector.timer` | no | yes | weekly mirrorlist refresh: the 20 most recently synchronized HTTPS mirrors sorted by download rate (`/etc/xdg/reflector/reflector.conf`, edited at build time by the pacman hook `42-monos-reflector-conf.hook`) |
| `ufw.service` | yes | yes | `ENABLED=yes` is set in `/etc/ufw/ufw.conf` at build time (pacman hook `41-monos-ufw-enable.hook`, the file belongs to the ufw package); default policy deny incoming, allow outgoing |
| `thermald.service` | yes | Intel CPUs only | skipped in VMs (`ConditionVirtualization=no`) |
| VM guest tools | yes | matching hypervisor only | units have virtualization conditions |
| fwupd | D-Bus activated | D-Bus activated | Discover refreshes the LVFS metadata; no timer |

The firewall blocks incoming connections, so KDE Connect cannot find your
phone until you open its ports: `sudo ufw allow 1714:1764/udp` and
`sudo ufw allow 1714:1764/tcp` (or System Settings > Firewall). Docker
publishes container ports through its own iptables rules, which bypass ufw.

## Phase 3: theming

Everything is themed from one palette, `branding/palette/monos.toml` (brand
colors, a dark UI scale and a 16-color terminal palette with WCAG contrast
targets, plus the monOS Light scale and terminal palette in `[light.ui]` /
`[light.ansi]`). Two scripts turn it into files of the archiso profile:

```sh
./branding/tools/install-branding.sh   # artwork + runs gen-themes.py
python3 branding/tools/gen-themes.py   # text configs only
python3 branding/tools/gen-themes.py --check   # contrast report only
./branding/tools/make-wallpapers.sh [orbit] [nebula] [space] [daylight] [astronaut]   # redraw wallpapers
```

`install-branding.sh` needs `imagemagick` and `librsvg` (and `grub-mkfont`
plus `noto-fonts` for the GRUB fonts). Both scripts are deterministic: running
them again changes nothing. Generated files say so in their first line; do not
edit them by hand, change the palette or the generator instead.

The overlay is copied into the live root filesystem, and the installer copies
that filesystem to disk, so the same theme applies to the live session and to
the installed system.

| Area | What | How it becomes the default |
|------|------|----------------------------|
| KDE Plasma | Global Themes `org.monos.desktop` (monOS, default: MonosDark colors, Bibata-Modern-Ice cursor, Orbit wallpaper) and `org.monos.desktop.light` (monOS Light: MonosLight colors, Bibata-Modern-Classic cursor, Daylight wallpaper); both with Yamis monochrome icons (Papirus-Dark fallback), Klassy style and window decoration, the monOS splash and [panel layout B](#desktop-layout); wallpapers monOS Orbit, Nebula and Daylight | `/etc/xdg/kdeglobals` (`LookAndFeelPackage`, `DefaultDarkLookAndFeel`, `DefaultLightLookAndFeel`, colors, fonts, icons, style, animation speed), `/etc/xdg/ksplashrc`, `/etc/xdg/kscreenlockerrc`; Plasma applies the Global Theme defaults and its panel layout at a user's first login |
| Klassy | rounded windows (radius 8), title bar in the window color without separator, round buttons with the monOS accent on hover/press, accent outline on the active window, slightly translucent menus | `/etc/xdg/klassy/klassyrc` (Klassy reads it as defaults; Klassy Settings writes user overrides to `~/.config/klassy/klassyrc`) |
| KWin | Klassy decoration, blur (lighter than Plasma's default), animations at 0.7x duration, 4 virtual desktops in one row, Night Light on (sunset/sunrise schedule), Krohnkite installed but off (when on: 8 px gaps, Tile/Monocle/Columns/Floating layouts, dialogs float, installer/KRunner/Spectacle/pinentry/polkit windows ignored; `[Script-krohnkite]`) | `/etc/xdg/kwinrc`, `/etc/xdg/kdeglobals` (`AnimationDurationFactor`) |
| Cursor | Bibata-Modern-Ice, 24 px, for Plasma, GTK apps and the SDDM greeter (monOS Light switches Plasma to Bibata-Modern-Classic) | `/etc/xdg/kcminputrc` (also synced to GTK by kde-gtk-config at login), Global Theme defaults, `/etc/sddm.conf.d/10-monos-theme.conf` |
| Shortcuts | see the table below | `/etc/skel/.config/kglobalshortcutsrc` (new users), `X-KDE-Shortcuts` in `/usr/local/share/applications/monos-tiling-toggle.desktop` (all users) |
| Dolphin | details view, hidden files shown, editable location bar with the full path, full path in the title bar | `/etc/xdg/dolphinrc`, `/etc/skel/.local/share/dolphin/view_properties/global/.directory` |
| Obsidian | `monOS` theme (monOS dark and monOS Light, JetBrainsMono Nerd Font, radius 4-12 px), selected in every vault that has not chosen a theme | `/usr/share/monos/obsidian/themes/monOS`, copied into each vault by `monos-obsidian-theme-sync` (see [Obsidian](#obsidian)) |
| VS Code (Code - OSS) | `monOS` color theme (workbench, terminal ANSI colors, syntax and semantic tokens), JetBrainsMono Nerd Font with ligatures, Seti icons, custom title bar, telemetry off | theme: built-in extension `/usr/lib/code/extensions/monos-theme`; settings: `/etc/skel/.config/Code - OSS/User/settings.json` |
| Terminals and CLI | kitty (plus `monOS` / `monOS Light` themes for `kitty +kitten themes`), foot, btop, yazi (theme and yatline bars), bat (`--theme=ansi`), fzf, lazygit, zellij, helix, starship, fastfetch; behavior: see [Shell & CLI defaults](#shell--cli-defaults) | files in `/etc/skel/.config` (and a block in `/etc/skel/.zshrc`), copied to new users' homes |
| Neovim / Vim | `monos` colorscheme only (no plugins, no user config) | `/usr/local/share/nvim/site` and `/usr/share/vim/vimfiles`; used when the user config does not pick a colorscheme |
| Login | SDDM theme `monos` (Qt 6 QML, see [Login screen](#login-screen-sddm)), Bibata cursor; Breeze keeps a monOS background and logo if you pick it instead | `/usr/share/sddm/themes/monos`, `/etc/sddm.conf.d/10-monos-theme.conf`, `/usr/share/sddm/themes/breeze/theme.conf.user` |
| Boot splash | Plymouth theme `monos` (logo, spinner, LUKS password prompt) | build-time pacman hook runs `plymouth-set-default-theme monos`; live: `plymouth` hook in the archiso initramfs and `quiet splash` on the default boot entries; installed: Calamares adds the `plymouth` hook and `splash` automatically |
| Boot menu | GRUB theme `monos` (installed system), Syslinux splash and colors (BIOS live medium) | the installer copies the theme to `/boot/grub/themes/monos`; `grubcfg` sets `GRUB_THEME` and `GRUB_TERMINAL_OUTPUT=gfxterm` |
| Installer | Calamares sidebar colors and slideshow background | `etc/calamares/branding/monos` |

Default shortcuts:

| Shortcut | Action |
|----------|--------|
| Meta+Return, Ctrl+Alt+T | kitty |
| Meta+E | Dolphin (Plasma default) |
| Meta+B | Firefox |
| Meta+1 .. Meta+4 | switch to virtual desktop 1..4 (Meta+F1..F4 and Ctrl+F1..F4 still work) |
| Meta+Shift+1 .. Meta+Shift+4 | move the window to desktop 1..4 |
| Meta+Shift+T | turn dynamic tiling (Krohnkite) on/off (`monos-tiling-toggle [on\|off]`) |

Notes on shortcuts:

- kglobalaccel reads only the user's `~/.config/kglobalshortcutsrc` (no
  `/etc/xdg` or Global Theme defaults), so these come from `/etc/skel` and
  apply to the live user and to users created by the installer. Change them in
  System Settings > Keyboard > Shortcuts.
- Meta+1..4 normally activate task manager entries; monOS frees them for the
  virtual desktops (Meta+5..9 still activate entries).
- KWin sees Meta+Shift+<digit> as Meta+<symbol of the keyboard layout>, so the
  "move window" shortcuts are bound for the US, Spanish and Latin American
  layouts (`!`, `@`/`"`, `#`/`·`, `$`). With another layout, set them once in
  System Settings.
- While Krohnkite is on, its own shortcuts are active (Meta+H/J/K/L focus,
  Meta+Shift+H/J/K/L move, Meta+F float, `Meta+\` next layout, ...; see
  System Settings > Keyboard > Shortcuts > KWin). Its "Set master" is moved to
  Meta+Shift+Return because Meta+Return opens kitty. Meta+T stays KWin's tile
  editor.

### Desktop layout

Both Global Themes ship the same panel layout ("B"), written by
`gen-themes.py` into `contents/layouts/org.kde.plasma.desktop-layout.js`
(Plasma 6 desktop scripting; panel properties checked against
plasma-workspace 6.7 `shell/scripting/panel.cpp`, widget keys against each
widget's `main.xml` in plasma-desktop / plasma-workspace 6.7.5):

| Panel | Settings | Widgets (left to right) |
|-------|----------|-------------------------|
| Top bar | `location = "top"`, floating, full width (`lengthMode = "fill"`), `hiding = "none"`, ~36 px (`2 * gridUnit`) | three islands: **launcher** (Kickoff with the monOS icon) and the **virtual desktops** (Kara: GNOME-style accent pill for the current desktop, dots for the others) and the **active window** (its icon and application name, Window Title); the **clock** (`Thu 1 Oct   14:52`: date beside the time, 24-hour, calendar on click), centered by two expanding spacers; **CPU and RAM** as labelled text (`org.kde.plasma.systemmonitor`, text-only face, colored dots), the **system tray** and a **session** button (opens the logout screen: log out, restart, shut down) |
| Dock | `location = "bottom"`, floating, `lengthMode = "fit"`, `alignment = "center"`, `hiding = "dodgewindows"`, ~60 px thick (about 48 px icons) | **app grid** (Application Dashboard, `applications-all-symbolic` icon); separator; icon-only task manager pinned with kitty, Dolphin, Firefox, Code - OSS and Obsidian; separator; Trash |

The task manager shows running indicators, badges and progress (Unity
launcher API), window thumbnails in its tooltips (hovering one highlights
that window), audio indicators with click-to-mute and media controls; a
middle click opens a new instance, the mouse wheel cycles the hovered
app's windows, and clicking a group shows its thumbnails.

The top bar never hides, so Plasma reserves its space: maximized and tiled
windows (Krohnkite too) start below it. The dock does not reserve space; it
slides away when a window overlaps it and comes back when no window covers
it or when the pointer touches the bottom edge. There is no "show desktop"
button (Meta+D still works).

**Panel Colorizer** (AUR `plasma6-applets-panel-colorizer`, a third-party
widget) draws the look: the top bar itself is transparent and each group of
widgets between two spacers becomes a rounded "island"; the dock gets one
rounded surface. Both use the color scheme's view background, slightly
translucent with KWin's blur behind, a 1 px accent outline, 8 px corners
(Klassy's window radius) and a soft shadow; a hovered widget lifts to the
overlay color and a widget with an open popup gets an accent outline. The
colors come from the active color scheme, so MonosDark and MonosLight both
look right. One hidden Panel Colorizer widget sits at the end of each
panel (visible in Edit Mode); its settings are written by the layout
script. The same settings are available as presets ("monOS Islands",
"monOS Dock" and their Light versions) in the widget's Presets page
(`~/.config/panel-colorizer/presets/`). If the widget breaks after a Plasma
update, or is removed, the panels keep working with Plasma's own
translucent background: only the extra styling is lost. The layout script
skips the widget when it is not installed.

**Kara** (AUR `plasma6-applets-kara`, a third-party widget) shows the
virtual desktops GNOME-style: the current desktop is a 28 px pill in the
monOS blue (the color scheme's selection color), every other desktop an
8 px dot in the color scheme's text color at half opacity, with no
numbers; on a switch the old pill shrinks to a dot and the new one grows
(200 ms animation). Click a dot to switch to that desktop, or scroll over
the widget to step through them (wrapping around). Its
settings are written by the layout script (Kara's pill style, `type` 0).
If Kara is not installed, the layout script uses Plasma's stock pager
instead (desktops labelled 1-4, no window outlines).

**Window Title** (AUR `plasma6-applets-window-title`, a third-party
widget) follows Kara in the same island: the icon and application name of
the active window on that screen, in the color scheme's text color,
elided on the right past 360 px (the full name is in its tooltip). On the
bare desktop it shows nothing. A double click maximizes or restores the
window; its scroll (minimize) and middle-click (close) actions are turned
off. The layout script skips it when it is not installed.

The layout is applied at a user's first login. To get it again: System
Settings > Colors & Themes > Global Theme > monOS (or monOS Light), check
"Desktop and window layout", Apply. That replaces your current panels.

### monOS Light

`org.monos.desktop.light` is the light variant of the desktop: the
`MonosLight` color scheme (from `[light.ui]` / `[light.ansi]`; views on the
lightest surface, windows one step darker, OSDs and the logout screen stay
dark like Breeze Light), the monOS Daylight wallpaper and the black
Bibata-Modern-Classic cursor. The rest is shared with the dark theme:

- Klassy: `/etc/xdg/klassy/klassyrc` only uses color roles of the scheme
  (title bar text, accent), no fixed colors, so it follows MonosLight.
- Icons: Yamis stays. Almost all of its SVGs (4076 of 4107) and its
  Papirus-Dark fallbacks draw with `ColorScheme-Text` / `currentColor` and
  the theme sets `FollowsColorScheme=true`, so KDE paints them dark on the
  light scheme. GTK apps do not recolor icons, so a few GTK dialogs may show
  light icons on a light background.
- Splash: both themes use the dark monOS splash (the mascot is white).
- Terminals and CLI tools keep the dark palette: they do not follow the
  Plasma theme. kitty has both palettes as user themes: run
  `kitty +kitten themes`, pick "monOS Light" (or "monOS" to go back) and it
  adds an include to `kitty.conf`. Nothing switches automatically.
- Obsidian has its own light colors (`.theme-light`) and follows its own
  Light/Dark setting.

Switching between dark, light and automatic: System Settings > Quick
Settings, row "Theme": monOS Light, monOS or Automatic. Those two buttons
come from `DefaultLightLookAndFeel` / `DefaultDarkLookAndFeel` in
`/etc/xdg/kdeglobals` (`[KDE]`, read by the Quick Settings page,
`kcm_landingpage`). Automatic sets `AutomaticLookAndFeel=true`: the
`lookandfeelautoswitcher` kded module then applies monOS Light during the
day and monOS at night, following the system's day/night schedule (the
KNightTime service, which Night Light uses too). Switching applies the colors, icons,
cursor, wallpaper and window decoration, never the panel layout. monOS
(dark) stays the default. The same choice is in System Settings > Colors &
Themes > Global Theme.

### Login screen (SDDM)

`/usr/share/sddm/themes/monos` is a Qt 6 QML greeter theme
(`QtVersion=6` in `metadata.desktop`, so SDDM 0.21 starts
`sddm-greeter-qt6`). It only imports Qt Quick, Qt Quick Controls (Basic),
Qt Quick Effects and SDDM's own `SddmComponents` (translated strings): no
Plasma or Kirigami. It shows:

- the Nebula sky without its wordmark (`background.jpg` in the theme folder,
  rendered by `make-wallpapers.sh space` and installed by
  `install-branding.sh`), blurred and dimmed: the card already shows the
  logo, and the Orbit mascot would sit right where the form is; the blur
  needs a GPU scene graph, with the software renderer the picture shows
  unblurred;
- the monOS wordmark and the host name (top left), suspend / reboot / shut
  down (top right, only those the system allows);
- a large clock with the date, then a translucent card with the users
  (picture, or their initial on an accent circle), the password field with
  a show/hide button and the login button; Caps Lock warning and "Login
  failed" (the card shakes and the field is cleared); a user name field when
  SDDM lists no users;
- the session picker (Wayland sessions first, so Plasma (Wayland) is the
  default until you pick another one; Plasma (X11) appears only if it is
  installed) and the keyboard layout (click to switch).

Keyboard: the password field has the focus; Enter logs in; Tab goes
show/hide, login, session, layout, power buttons, then the user list
(Left/Right picks a user). Colors, fonts (JetBrainsMono Nerd Font Propo),
background, blur, dimming, clock and date formats are in `theme.conf`,
rendered by `gen-themes.py` from the palette; put local changes in
`theme.conf.user` next to it. `/etc/sddm.conf.d/10-monos-theme.conf`
selects the theme for the live session and the installed system. To try it
without logging out: `sddm-greeter-qt6 --test-mode --theme
/usr/share/sddm/themes/monos`.

### Obsidian

`gen-themes.py` renders the `monOS` Obsidian theme
(`/usr/share/monos/obsidian/themes/monOS/{manifest.json,theme.css}`):
`.theme-dark` uses the dark palette, `.theme-light` the `[light.ui]` /
`[light.ansi]` palette (monOS Light). Brand blue is used for buttons and
checkboxes; links, tags and accent text use the text-safe accent. It covers
backgrounds, borders, text, headings, links, code, callouts, tags, tables,
blockquotes, checkboxes, selection, scrollbars and the graph view.

Obsidian only loads themes from inside each vault, so the systemd user units
`monos-obsidian-theme.path` (watches `~/.config/obsidian/obsidian.json`, the
vault list, also the Flatpak location) and `monos-obsidian-theme.service`
(at login), enabled for every user in `/etc/systemd/user/default.target.wants`,
run `/usr/local/bin/monos-obsidian-theme-sync`. For each existing vault it
refreshes `.obsidian/themes/monOS` (only its own two files) and, if
`.obsidian/appearance.json` has no `cssTheme` key, sets `"cssTheme": "monOS"`
keeping the other settings. A theme you picked, including Obsidian's default,
is never changed. Run the script by hand to apply the theme right away;
disable it with `systemctl --user disable --now monos-obsidian-theme.path
monos-obsidian-theme.service`.

fastfetch is not started automatically: run `fastfetch` (ASCII logo, any
terminal) or, in kitty, `fastfetch -c monos-kitty` (logo as an image).

To re-apply the desktop theme after changing it (for example to get the
default panels back): System Settings > Colors & Themes > Global Theme >
monOS (or monOS Light), check "Desktop and window layout", Apply. In Neovim/Vim the scheme
is `:colorscheme monos` (disable the automatic default with
`vim.g.monos_no_default_colorscheme = true` / `let g:monos_no_default_colorscheme = 1`).
Plymouth: `sudo plymouth-set-default-theme -R <theme>`. Klassy: run
`klassy-settings` (or System Settings > Colors & Themes > Window Decorations >
Klassy). VS Code: the theme is picked with Ctrl+K Ctrl+T > monOS.

The UEFI live medium boots with systemd-boot, which has no theme support.

## Shell & CLI defaults

New users get these files from `/etc/skel` (root uses the same `.zshrc`, which
falls back to the modules and Starship config in `/etc/skel` because root has
no `~/.config/zsh`). Everything works offline: plugins come from Arch packages
or are vendored, nothing is cloned or downloaded at runtime.

Which files are generated: `gen-themes.py` writes everything with colors
(`.zshrc` fzf block and its `/root/.zshrc` copy, `starship.toml`,
`fastfetch/config.jsonc` and the `monos-kitty` preset, `kitty.conf`,
`yazi/theme.toml`, `yazi/init.lua`). The rest are plain files edited by hand:
`~/.config/zsh/*`, `atuin/config.toml`, `mpv/mpv.conf`, `yazi/yazi.toml`,
`yazi/keymap.toml` and the vendored `yazi/plugins/`.

### Zsh

`~/.zshrc` only sources the modules in `~/.config/zsh`, in this order:
`env.zsh` (PATH with `~/.local/bin`, `EDITOR`=nvim or vim, man pages through
bat), `options.zsh` (history in `~/.local/state/zsh/history`, 100k entries,
shared between shells, with timestamps; `auto_cd`), `completion.zsh`
(menu selection, case-insensitive, `LS_COLORS`, cached), `keybinds.zsh`,
`functions/*.zsh`, `integrations.zsh` (starship, zoxide, direnv, fzf, atuin),
`plugins.zsh` (zsh-autosuggestions, then zsh-syntax-highlighting),
`aliases.zsh` (last, so its global alias never reaches the code sourced
before it) and an optional `~/.config/zsh/local.zsh` for your own additions.
No Oh My Zsh and no plugin manager.

| Key | Action |
|-----|--------|
| Ctrl-R | search the history with atuin (Enter runs, Tab edits; local database, no sync unless you `atuin login`) |
| Up / Down | previous/next command starting with what you typed |
| Ctrl-T / Alt-C | fzf: insert a file path / cd into a directory (with previews) |
| Esc Esc | add or remove `sudo ` at the start of the line (previous command if the line is empty) |
| Alt-1 .. Alt-9 | insert the command run 1..9 commands ago |
| `?` after `command ` | runs `command --help` (`git commit ?`); a `?` anywhere else is typed normally |
| Home / End / Delete, Ctrl-Left / Ctrl-Right, Ctrl-Backspace / Ctrl-Delete | line start/end, delete, word movement, delete word |
| Right / End | accept the gray autosuggestion (Ctrl-Right: one word) |

| Alias | Command |
|-------|---------|
| `ls`, `l`, `ll`, `la`, `lt`, `ld` | eza: grid, long, long + hidden + git, grid + hidden, tree (2 levels), directories only (icons, directories first) |
| `cat` | `bat --style=plain --paging=never` |
| `<cmd> --help` | help text colored by bat (global alias; write `\--help` for raw output) |
| `df` | `duf` (`df -h` and `df <path>` keep working) |
| `c`, `lg` | `clear`, `lazygit` |
| `up`, `un`, `pl`, `pa`, `pc`, `po` | update system, remove package (`-Rns`), search installed, search repos, clean cache, remove orphans. They use `yay` when it is installed (AUR included), else `sudo pacman` (queries without sudo); as root, `pacman` |

| Function | Action |
|----------|--------|
| `y [dir]` | yazi; quitting with `q` leaves the shell in yazi's directory |
| `ffcd [query]` | fuzzy-pick a directory below `.` and cd into it |
| `ffe [query]` | fuzzy-pick a file and open it in `$EDITOR` (bat preview) |
| `ffec [pattern]` | pick a file whose content matches (ripgrep, case-insensitive) and open it |

The finders skip `.git`, `node_modules`, `.venv`, `target`, `.cache` and
`__pycache__` (and, with fd, what `.gitignore` ignores). `z <dir>` / `zi`
come from zoxide, `.envrc` files from direnv (`direnv allow` first).

### Prompt, terminal and tools

- Starship: one line. Left: distro glyph, directory, git branch, commit,
  state and status, `❯`. Right: the project's language/tool (C, C++, CMake,
  Go, Rust, Python with virtualenv and version, Node.js when a `package.json`
  exists, Java, Kotlin, Lua, PHP, Ruby, .NET, Docker context, Nix shell),
  memory above 75 %, duration of commands over 2 s, exit status of failed
  commands, time. AWS is disabled.
- fastfetch: two boxes (chassis, OS, kernel, packages, display, terminal, DE;
  then user@host, CPU, GPU, GPU driver, memory, "OS Age" = days since `/` was
  created, uptime) and the color dots. Same layout with the image logo in
  `fastfetch -c monos-kitty`.
- kitty: 0.92 opacity with compositor blur (KWin), 6 px padding, cursor
  trail, slanted powerline tabs at the bottom (`:N:` = windows in the tab),
  no bell. Remote control only through the per-instance socket
  `/tmp/kitty-<pid>` (`kitten @ ...`); set `allow_remote_control no` if you
  do not want any process of your user to be able to control kitty.
- mpv: `gpu-next` output, safe hardware decoding, demuxer cache, resume
  position, stay open at the end, screenshots as PNG in `~/Pictures/Screenshots`.
- atuin: Enter runs the selected command, compact list 20 lines high, no
  update checks.

### yazi

`y` starts it. Layout 1:3:4, natural sort with directories first, full
border, yatline status bars in the monOS colors, relative line numbers.
Openers: `$EDITOR` for text, `xdg-open` for the rest, `ouch` to extract
archives. Previews: Markdown with glow, archives with ouch, media with
mediainfo (cover + metadata, `I` toggles), binaries as a hex dump (hexyl);
nothing is preloaded/previewed under `/run/media` (USB drives) and GVFS mounts.

| Key | Action |
|-----|--------|
| `l` / Right / Enter | enter a directory (skipping single-child directories) or open the file |
| `1`-`9` then `j`/`k` | relative motions (`3j`) |
| `s n` / `s a` / `s m` / `s s` | sort natural / alphabetical / newest first / largest first |
| `T` / `X` / Tab / Shift-Tab | new tab / close tab / next / previous tab |
| `y` / Ctrl-P | yank and copy the paths to the clipboard / paste files from the clipboard |
| `f g` / `f G` / `f f` | search contents (fuzzy) / contents (exact) / file names, jump to the result |
| `M m` / `M u` / `g m` | GVFS: mount a phone or share / unmount / jump to a mounted device |
| `M M` | mount manager for local disks (udisks2) |
| `R b` / `R r` / `R e` | trash: menu / restore / empty |
| `C` / Ctrl-S / `g i` / `!` | compress with ouch / size of selection / lazygit / open a shell here |

These replace yazi defaults: `s` (fd search: use `f f`), `f` (filter), `1`-`9`
(tab N), Tab (file info), `X`, Ctrl-S. F1 or `~` lists every key.

The plugins are vendored in `/etc/skel/.config/yazi/plugins`, unmodified, at
pinned commits (`plugins/monos-plugins.txt`). Update or re-vendor them with
`./branding/tools/vendor-yazi-plugins.sh` (needs network; edit the commit
list at the top of the script). Each keeps its own license file:

| Plugin | Author / repository | License | Commit |
|--------|---------------------|---------|--------|
| bypass | Rolv-Apneseth/bypass.yazi | MIT | `4a0c70e` |
| clipboard | XYenon/clipboard.yazi | AGPL-3.0 | `b25ec96` |
| fg | DreamMaoMao/fg.yazi | MIT | `b9fb819` |
| full-border, mount, piper | yazi-rs/plugins | MIT | `4dc7f1b` |
| gvfs | boydaihungst/gvfs.yazi | MIT | `a85d659` |
| lazygit | Lil-Dank/lazygit.yazi | MIT | `e73fd74` |
| mediainfo | boydaihungst/mediainfo.yazi | MIT | `d2dd310` |
| ouch | ndtoan96/ouch.yazi | MIT | `cfe4f50` |
| recycle-bin | uhs-robert/recycle-bin.yazi | MIT | `fe48a02` |
| relative-motions | dedukun/relative-motions.yazi | MIT | `a603d9e` |
| what-size | pirafrank/what-size.yazi | MIT | `ec94d9a` |
| yatline | imsi32/yatline.yazi | MIT | `c5d4b48` |

Not included: rich-preview (needs `rich-cli`, AUR only), simple-mtp (no
license, needs `simple-mtpfs`, AUR only; GVFS covers MTP phones) and
system-clipboard (needs the `cb` tool, not in the Arch repositories; the
clipboard plugin above uses `wl-clipboard`).

## Structure

```text
.
├── build.sh              # builds the ISO (run with sudo)
├── test.sh               # boots the newest ISO / the installed disk in QEMU
├── aur/
│   ├── build.sh          # builds AUR packages into localrepo/ (run as user)
│   └── patches/          # patches applied to AUR PKGBUILDs
├── branding/             # palette, logos, wallpapers and theming scripts (tools/)
├── localrepo/            # local pacman repo (generated, not committed)
└── profile/              # archiso profile (based on releng)
    ├── profiledef.sh     # ISO metadata and file permissions
    ├── packages.x86_64   # package list, grouped by purpose
    ├── pacman.conf
    ├── airootfs/         # files copied into the live root filesystem
    │   ├── etc/          # os-release, users, SDDM autologin, services, KDE defaults, skel
    │   ├── etc/calamares # installer settings, modules, branding, helper scripts
    │   ├── usr/local/    # installer launcher (monos-install), tiling toggle, Obsidian theme sync, NVIDIA gate, menu entries
    │   └── home/liveuser # installer desktop icon (dotfiles come from etc/skel)
    ├── efiboot/          # systemd-boot entries (UEFI)
    ├── grub/             # GRUB menus
    └── syslinux/         # Syslinux menus (BIOS)
```
