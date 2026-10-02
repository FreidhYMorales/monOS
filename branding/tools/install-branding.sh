#!/usr/bin/env bash
# Install the monOS artwork into the archiso profile, then render the themes.
#
# Usage: ./branding/tools/install-branding.sh
#
# Copies/derives every binary asset from branding/ (logo SVGs, wallpapers)
# into profile/airootfs and profile/syslinux, then runs gen-themes.py, which
# renders all text configuration from branding/palette/monos.toml.
#
#   icons       /usr/share/icons/hicolor/scalable/apps/monos{,-small}.svg
#   logos       /usr/share/monos/logo/*.svg, fastfetch image logo
#   wallpapers  /usr/share/wallpapers/monOS-{Orbit,Nebula,Daylight} (KDE packages)
#   Plasma      Global Theme previews (monOS, monOS Light) and splash logo
#   SDDM        /usr/share/sddm/themes/monos/background.jpg (nebula, no wordmark)
#   Plymouth    /usr/share/plymouth/themes/monos/*.png
#   GRUB        /usr/share/grub/themes/monos (background, pixmaps, PF2 fonts)
#   Syslinux    profile/syslinux/splash.png (640x480)
#   Calamares   slideshow background
#
# Requires: python3 (3.11+), imagemagick (magick), librsvg (rsvg-convert).
# Optional: grub-mkfont and the noto-fonts TTFs (GRUB fonts). Without them the
# committed PF2 fonts are kept (or the theme falls back to GRUB's unicode.pf2).
# Output is deterministic (no timestamps), so re-running changes nothing.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BRANDING="$(dirname -- "${SCRIPT_DIR}")"
ROOT="$(dirname -- "${BRANDING}")"
PALETTE="${BRANDING}/palette/monos.toml"
LOGO="${BRANDING}/logo"
WALLS="${BRANDING}/wallpapers"
AIROOTFS="${ROOT}/profile/airootfs"
SYSLINUX="${ROOT}/profile/syslinux"

for tool in python3 magick rsvg-convert; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
        echo "error: '${tool}' is required" >&2
        exit 1
    fi
done

TMP="$(mktemp -d)"
trap 'rm -rf -- "${TMP}"' EXIT

# pal <section.key>: read a color from the palette.
pal() {
    python3 -c 'import sys, tomllib
d = tomllib.load(open(sys.argv[1], "rb"))
s, k = sys.argv[2].split(".", 1)
print(d[s][k])' "${PALETTE}" "$1"
}
BG="$(pal ui.bg)"
SURFACE="$(pal ui.surface)"
SURFACE2="$(pal ui.surface2)"
BORDER="$(pal ui.border)"
FG="$(pal ui.fg)"
FG_DIM="$(pal ui.fg-dim)"
MUTED="$(pal ui.muted)"
ACCENT="$(pal ui.accent)"
OVERLAY="$(pal ui.overlay)"

# Deterministic image output: no metadata, no timestamps. PNGs that GRUB or
# Plymouth read are written as 8-bit RGBA ("PNG32:"): GRUB's PNG decoder does
# not support palette images, which ImageMagick picks for few-color images.
STRIP=(-strip -define png:exclude-chunks=date,time)

# svg <in.svg> <height> <out.png>: rasterize with transparency.
svg() {
    rsvg-convert --height "$2" --keep-aspect-ratio "$1" -o "${TMP}/svg.png"
    magick "${TMP}/svg.png" "${STRIP[@]}" "PNG32:$3"
}

# nine_slice <prefix> <fill> <radius> <piece> <outdir> [stroke]: rounded box
# cut into the 9 pixmaps GRUB uses for styled boxes (prefix_{nw,n,...,c}.png).
nine_slice() {
    local prefix="$1" fill="$2" r="$3" p="$4" dir="$5" stroke="${6:-none}"
    local size=$((p * 3))
    magick -size "${size}x${size}" xc:none -fill "${fill}" -stroke "${stroke}" \
        -draw "roundrectangle 0,0 $((size - 1)),$((size - 1)) ${r},${r}" "${TMP}/box.png"
    local name x y
    local -A pos=([nw]="0,0" [n]="1,0" [ne]="2,0" [w]="0,1" [c]="1,1" [e]="2,1"
                  [sw]="0,2" [s]="1,2" [se]="2,2")
    for name in "${!pos[@]}"; do
        IFS=, read -r x y <<<"${pos[${name}]}"
        magick "${TMP}/box.png" -crop "${p}x${p}+$((x * p))+$((y * p))" +repage \
            "${STRIP[@]}" "PNG32:${dir}/${prefix}_${name}.png"
    done
}

echo ":: Icons and logos"
icons="${AIROOTFS}/usr/share/icons/hicolor/scalable/apps"
install -d -- "${icons}" "${AIROOTFS}/usr/share/monos/logo" "${AIROOTFS}/usr/share/monos/fastfetch"
install -m 0644 -- "${LOGO}/monos-icon.svg" "${icons}/monos.svg"
# monos-small and monos-launcher crop the mascot with <clipPath>, which Qt's
# SVG renderer (SVG Tiny, used by Plasma for icons) ignores: it would draw the
# whole mascot spilling out of the badge. Ship them pre-rendered as PNGs in
# every standard hicolor size instead of as scalable SVGs.
rm -f -- "${icons}/monos-small.svg" "${icons}/monos-launcher.svg"
for px in 16 22 24 32 48 64 96 128 256 512; do
    dir="${AIROOTFS}/usr/share/icons/hicolor/${px}x${px}/apps"
    install -d -- "${dir}"
    svg "${LOGO}/monos-icon-small.svg" "${px}" "${dir}/monos-small.png"
    svg "${LOGO}/monos-launcher.svg" "${px}" "${dir}/monos-launcher.png"
done
for name in monos-icon monos-icon-small monos-logo monos-mark monos-wordmark; do
    install -m 0644 -- "${LOGO}/${name}.svg" "${AIROOTFS}/usr/share/monos/logo/${name}.svg"
done
svg "${LOGO}/monos-mark.svg" 512 "${AIROOTFS}/usr/share/monos/fastfetch/monos.png"

echo ":: Wallpapers (KDE wallpaper packages)"
wallpaper() { # <source.jpg> <package id> <display name>
    local dir="${AIROOTFS}/usr/share/wallpapers/$2"
    install -d -- "${dir}/contents/images"
    install -m 0644 -- "$1" "${dir}/contents/images/3840x2160.jpg"
    magick "$1" -resize 640x360 -quality 85 "${STRIP[@]}" "${dir}/contents/screenshot.jpg"
    cat >"${dir}/metadata.json" <<EOF
{
    "KPlugin": {
        "Authors": [
            {
                "Name": "monOS Project"
            }
        ],
        "Id": "$2",
        "License": "CC-BY-SA-4.0",
        "Name": "$3"
    }
}
EOF
}
wallpaper "${WALLS}/monos-orbit.jpg" monOS-Orbit "monOS Orbit"
wallpaper "${WALLS}/monos-nebula.jpg" monOS-Nebula "monOS Nebula"
wallpaper "${WALLS}/monos-daylight.jpg" monOS-Daylight "monOS Daylight"

echo ":: Plasma Global Theme (previews, splash logo)"
lnf="${AIROOTFS}/usr/share/plasma/look-and-feel/org.monos.desktop/contents"
install -d -- "${lnf}/previews" "${lnf}/splash/images"
install -m 0644 -- "${LOGO}/monos-logo.svg" "${lnf}/splash/images/monos.svg"
magick "${WALLS}/monos-orbit.jpg" -resize 600x338 "${STRIP[@]}" "PNG32:${lnf}/previews/preview.png"
magick "${WALLS}/monos-orbit.jpg" -resize 1920x1080 -quality 88 "${STRIP[@]}" \
    "${lnf}/previews/fullscreenpreview.jpg"
# monOS Light reuses the dark splash (org.monos.desktop), so only previews.
lnf_light="${AIROOTFS}/usr/share/plasma/look-and-feel/org.monos.desktop.light/contents"
install -d -- "${lnf_light}/previews"
magick "${WALLS}/monos-daylight.jpg" -resize 600x338 "${STRIP[@]}" "PNG32:${lnf_light}/previews/preview.png"
magick "${WALLS}/monos-daylight.jpg" -resize 1920x1080 -quality 88 "${STRIP[@]}" \
    "${lnf_light}/previews/fullscreenpreview.jpg"

echo ":: SDDM login background"
# The wordmark-free nebula (make-wallpapers.sh space): the login card shows
# the logo, so the background must not repeat it. 2560x1440 is plenty under
# the greeter's blur and dimming.
sddm="${AIROOTFS}/usr/share/sddm/themes/monos"
install -d -- "${sddm}"
magick "${WALLS}/monos-space.jpg" -resize 2560x1440 -quality 90 "${STRIP[@]}" "${sddm}/background.jpg"

echo ":: Plymouth theme images"
ply="${AIROOTFS}/usr/share/plymouth/themes/monos"
install -d -- "${ply}"
svg "${LOGO}/monos-logo.svg" 240 "${ply}/watermark.png"
# Spinner: a 90-degree arc in brand blue over a faint ring, 36 frames.
for i in $(seq 0 35); do
    start=$((i * 10))
    magick -size 48x48 xc:none -fill none -strokewidth 4 \
        -stroke "${OVERLAY}" -draw "arc 4,4 43,43 0,360" \
        -stroke "${ACCENT}" -draw "arc 4,4 43,43 ${start},$((start + 90))" \
        "${STRIP[@]}" "PNG32:${ply}/throbber-$(printf '%04d' $((i + 1))).png"
done
# Password dialog: entry field, bullet and lock icon.
magick -size 300x40 xc:none -fill "${SURFACE2}" -stroke "${BORDER}" -strokewidth 2 \
    -draw "roundrectangle 1,1 298,38 8,8" "${STRIP[@]}" "PNG32:${ply}/entry.png"
magick -size 12x12 xc:none -fill "${FG}" -draw "circle 6,6 6,1" "${STRIP[@]}" "PNG32:${ply}/bullet.png"
magick -size 32x32 xc:none -fill none -stroke "${FG_DIM}" -strokewidth 3 \
    -draw "arc 9,3 23,19 180,360" -draw "line 9,11 9,15" -draw "line 23,11 23,15" \
    -stroke none -fill "${FG_DIM}" -draw "roundrectangle 5,14 27,30 3,3" \
    "${STRIP[@]}" "PNG32:${ply}/lock.png"

# Nebula without its small wordmark (bottom right corner), for boot screens
# that show the full logo themselves.
magick "${WALLS}/monos-nebula.jpg" -crop 3300x1856+0+0 +repage "${TMP}/nebula-clean.png"

echo ":: GRUB theme"
grub="${AIROOTFS}/usr/share/grub/themes/monos"
install -d -- "${grub}"
svg "${LOGO}/monos-logo.svg" 300 "${TMP}/grub-logo.png"
magick "${TMP}/nebula-clean.png" -resize 1920x1080 \
    \( -size 1920x1080 xc:"${BG}" -alpha set -channel A -evaluate set 35% +channel \) \
    -compose Over -composite \
    "${TMP}/grub-logo.png" -gravity north -geometry +0+90 -compose Over -composite \
    -alpha off -sampling-factor 4:2:0 -interlace none -quality 90 "${STRIP[@]}" \
    "${grub}/background.jpg"
nine_slice select "${ACCENT}" 8 8 "${grub}"
nine_slice scrollbar_thumb "${MUTED}" 2 3 "${grub}"
nine_slice terminal_box "${SURFACE}" 6 6 "${grub}" "${BORDER}"

# PF2 fonts (Latin, arrows and box drawing only, to keep them small).
mkfont() { # <ttf> <size> <out.pf2>
    grub-mkfont -s "$2" -r 0x20-0x7E,0xA0-0x24F,0x2010-0x2027,0x2190-0x21FF,0x2500-0x259F \
        -o "${TMP}/font.pf2" "$1"
    install -m 0644 -- "${TMP}/font.pf2" "$3"
}
NOTO="/usr/share/fonts/noto"
if command -v grub-mkfont >/dev/null 2>&1 && [[ -f "${NOTO}/NotoSans-Regular.ttf" ]]; then
    mkfont "${NOTO}/NotoSans-Regular.ttf" 18 "${grub}/noto-sans-regular-18.pf2"
    mkfont "${NOTO}/NotoSans-Bold.ttf" 18 "${grub}/noto-sans-bold-18.pf2"
    mkfont "${NOTO}/NotoSans-Regular.ttf" 14 "${grub}/noto-sans-regular-14.pf2"
    mkfont "${NOTO}/NotoSansMono-Regular.ttf" 16 "${grub}/noto-sans-mono-regular-16.pf2"
else
    echo "   warning: grub-mkfont or noto-fonts missing, keeping the existing GRUB fonts" >&2
fi

echo ":: Syslinux splash (640x480)"
svg "${LOGO}/monos-logo.svg" 120 "${TMP}/sys-logo.png"
magick "${TMP}/nebula-clean.png" -resize 640x480^ -gravity center -extent 640x480 \
    \( -size 640x480 xc:"${BG}" -alpha set -channel A -evaluate set 50% +channel \) \
    -compose Over -composite \
    "${TMP}/sys-logo.png" -gravity north -geometry +0+22 -compose Over -composite \
    -alpha off -define png:color-type=2 "${STRIP[@]}" "${SYSLINUX}/splash.png"

echo ":: Calamares slideshow background"
magick "${WALLS}/monos-nebula.jpg" -resize 1280x720 -quality 85 "${STRIP[@]}" \
    "${AIROOTFS}/etc/calamares/branding/monos/background.jpg"

echo ":: Rendering themes from the palette"
python3 "${SCRIPT_DIR}/gen-themes.py"
