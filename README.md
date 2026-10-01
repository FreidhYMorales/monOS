# monOS

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

`klassy` is built from source rather than `klassy-bin`: the source package
compiles against the Plasma/KDecoration version installed on the build host,
while `klassy-bin` repackages a prebuilt openSUSE OBS binary without checksums
that can lag behind a Plasma update (KDecoration plugins break on ABI
changes). Its build dependencies (`extra-cmake-modules`, KF6 and KF5
development packages) are installed by `makepkg -s`. The PKGBUILD also
produces `klassy-qt5` (Qt5 style); it lands in `localrepo/` but is not
installed on the ISO.

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

## Phase 3: theming

Everything is themed from one palette, `branding/palette/monos.toml` (brand
colors, a dark UI scale and a 16-color terminal palette with WCAG contrast
targets). Two scripts turn it into files of the archiso profile:

```sh
./branding/tools/install-branding.sh   # artwork + runs gen-themes.py
python3 branding/tools/gen-themes.py   # text configs only
python3 branding/tools/gen-themes.py --check   # contrast report only
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
| KDE Plasma | Global Theme `org.monos.desktop` (MonosDark colors, Yamis monochrome icons with Papirus-Dark fallback, Klassy style and window decoration, Bibata-Modern-Ice cursor, splash, translucent floating bottom panel with Kickoff, pinned kitty/Dolphin/Firefox/Code, tray, clock, show desktop), wallpapers monOS Orbit and monOS Nebula | `/etc/xdg/kdeglobals` (`LookAndFeelPackage`, colors, fonts, icons, style, animation speed), `/etc/xdg/ksplashrc`, `/etc/xdg/kscreenlockerrc`; Plasma applies the Global Theme defaults and its panel layout at a user's first login |
| Klassy | rounded windows (radius 8), title bar in the window color without separator, round buttons with the monOS accent on hover/press, accent outline on the active window, slightly translucent menus | `/etc/xdg/klassy/klassyrc` (Klassy reads it as defaults; Klassy Settings writes user overrides to `~/.config/klassy/klassyrc`) |
| KWin | Klassy decoration, blur (lighter than Plasma's default), animations at 0.7x duration, 4 virtual desktops in one row, Night Light on (sunset/sunrise schedule), Krohnkite installed but off | `/etc/xdg/kwinrc`, `/etc/xdg/kdeglobals` (`AnimationDurationFactor`) |
| Cursor | Bibata-Modern-Ice, 24 px, for Plasma, GTK apps and the SDDM greeter | `/etc/xdg/kcminputrc` (also synced to GTK by kde-gtk-config at login), Global Theme defaults, `/etc/sddm.conf.d/10-monos-theme.conf` |
| Shortcuts | see the table below | `/etc/skel/.config/kglobalshortcutsrc` (new users), `X-KDE-Shortcuts` in `/usr/local/share/applications/monos-tiling-toggle.desktop` (all users) |
| Dolphin | details view, hidden files shown, editable location bar with the full path, full path in the title bar | `/etc/xdg/dolphinrc`, `/etc/skel/.local/share/dolphin/view_properties/global/.directory` |
| VS Code (Code - OSS) | `monOS` color theme (workbench, terminal ANSI colors, syntax and semantic tokens), JetBrainsMono Nerd Font with ligatures, Seti icons, custom title bar, telemetry off | theme: built-in extension `/usr/lib/code/extensions/monos-theme`; settings: `/etc/skel/.config/Code - OSS/User/settings.json` |
| Terminals and CLI | kitty, foot, btop, yazi (theme and yatline bars), bat (`--theme=ansi`), fzf, lazygit, zellij, helix, starship, fastfetch; behavior: see [Shell & CLI defaults](#shell--cli-defaults) | files in `/etc/skel/.config` (and a block in `/etc/skel/.zshrc`), copied to new users' homes |
| Neovim / Vim | `monos` colorscheme only (no plugins, no user config) | `/usr/local/share/nvim/site` and `/usr/share/vim/vimfiles`; used when the user config does not pick a colorscheme |
| Login | SDDM Breeze with the monOS Orbit background and logo, Bibata cursor | `/usr/share/sddm/themes/breeze/theme.conf.user`, `/etc/sddm.conf.d/10-monos-theme.conf` |
| Boot splash | Plymouth theme `monos` (logo, spinner, LUKS password prompt) | build-time pacman hook runs `plymouth-set-default-theme monos`; live: `plymouth` hook in the archiso initramfs and `quiet splash` on the default boot entries; installed: Calamares adds the `plymouth` hook and `splash` automatically |
| Boot menu | GRUB theme `monos` (installed system), Syslinux splash and colors (BIOS live medium) | the installer copies the theme to `/boot/grub/themes/monos`; `grubcfg` sets `GRUB_THEME` and `GRUB_TERMINAL_OUTPUT=gfxterm` |
| Installer | Calamares sidebar colors and slideshow background | `etc/calamares/branding/monos` |

Default shortcuts:

| Shortcut | Action |
|----------|--------|
| Meta+Return | kitty |
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

fastfetch is not started automatically: run `fastfetch` (ASCII logo, any
terminal) or, in kitty, `fastfetch -c monos-kitty` (logo as an image).

To re-apply the desktop theme after changing it (for example to get the
default panel back): System Settings > Colors & Themes > Global Theme >
monOS, check "Use desktop layout from theme", Apply. In Neovim/Vim the scheme
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
    │   ├── usr/local/    # installer launcher (monos-install), tiling toggle, menu entries
    │   └── home/liveuser # installer desktop icon (dotfiles come from etc/skel)
    ├── efiboot/          # systemd-boot entries (UEFI)
    ├── grub/             # GRUB menus
    └── syslinux/         # Syslinux menus (BIOS)
```
