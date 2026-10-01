#!/usr/bin/env bash
# Install the extra monOS wallpapers as KDE wallpaper packages in the profile.
#
# Usage: ./branding/tools/install-extra-wallpapers.sh
#
# Sources:
#   branding/wallpapers/gemini/*.jpg  AI-generated artwork (Google Gemini),
#                                     1376x768, used as-is for now.
#   branding/wallpapers/monos-astronaut{,-light}.jpg  line-art scene from
#                                     make-wallpapers.sh, packaged with a dark
#                                     and a light variant (images_dark/).
# Outputs profile/airootfs/usr/share/wallpapers/monOS-<Name>/. Each package
# names its image after the real pixel size, which is how Plasma picks the
# best match for the screen. Requires: imagemagick.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BRANDING="$(dirname -- "${SCRIPT_DIR}")"
WALLS="${BRANDING}/wallpapers"
AIROOTFS="$(dirname -- "${BRANDING}")/profile/airootfs"
STRIP=(-strip -define png:exclude-chunks=date,time)

size() { magick identify -format '%wx%h' "$1"; }

# <package id> <display name> <light/default image> [dark image]
wallpaper() {
    local dir="${AIROOTFS}/usr/share/wallpapers/$1"
    rm -rf -- "${dir}"
    install -d -- "${dir}/contents/images"
    install -m 0644 -- "$3" "${dir}/contents/images/$(size "$3").jpg"
    if [[ -n "${4:-}" ]]; then
        install -d -- "${dir}/contents/images_dark"
        install -m 0644 -- "$4" "${dir}/contents/images_dark/$(size "$4").jpg"
    fi
    magick "$3" -resize 640x360 -quality 85 "${STRIP[@]}" "${dir}/contents/screenshot.jpg"
    cat >"${dir}/metadata.json" <<EOF
{
    "KPlugin": {
        "Authors": [
            {
                "Name": "monOS Project"
            }
        ],
        "Id": "$1",
        "License": "CC-BY-SA-4.0",
        "Name": "$2"
    }
}
EOF
}

G="${WALLS}/gemini"
wallpaper monOS-Morning   "monOS Morning"   "${G}/monos-morning.jpg"
wallpaper monOS-Focus     "monOS Focus"     "${G}/monos-focus.jpg"
wallpaper monOS-Sketch    "monOS Sketch"    "${G}/monos-sketch.jpg"
wallpaper monOS-Spacewalk "monOS Spacewalk" "${G}/monos-spacewalk.jpg"
wallpaper monOS-Evolution "monOS Evolution" "${G}/monos-evolution.jpg"
wallpaper monOS-Matrix    "monOS Matrix"    "${G}/monos-matrix.jpg"
wallpaper monOS-Blueprint "monOS Blueprint" "${G}/monos-blueprint.jpg"
# Light image by default; Plasma shows images_dark/ with a dark color scheme.
wallpaper monOS-Astronaut "monOS Astronaut" \
    "${WALLS}/monos-astronaut-light.jpg" "${WALLS}/monos-astronaut.jpg"

echo ":: Extra wallpapers:"
ls -d -- "${AIROOTFS}"/usr/share/wallpapers/monOS-*
