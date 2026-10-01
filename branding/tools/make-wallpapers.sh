#!/usr/bin/env bash
# Generate the procedural monOS space wallpapers (3840x2160, brand palette).
#
# Usage: ./branding/tools/make-wallpapers.sh [orbit] [nebula] [daylight]
#
# Outputs branding/wallpapers/monos-orbit.jpg (glowing mascot),
# branding/wallpapers/monos-nebula.jpg (clean nebula + small wordmark) and
# branding/wallpapers/monos-daylight.jpg (light nebula for monOS Light).
# Without arguments all three are rendered. Seeds are fixed, so the output is
# reproducible. Requires: imagemagick.
set -euo pipefail

WANT=("$@")
[[ ${#WANT[@]} -gt 0 ]] || WANT=(orbit nebula daylight)
want() { [[ " ${WANT[*]} " == *" $1 "* ]]; }

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BRANDING="$(dirname -- "${SCRIPT_DIR}")"
LOGO="${BRANDING}/logo"
OUT="${BRANDING}/wallpapers"
TMP="$(mktemp -d)"
trap 'rm -rf -- "${TMP}"' EXIT
cd -- "${TMP}"

W=3840
H=2160
BLUE="#0C6BFA"
VIOLET="#7c3aed"
NIGHT="#05070c"

# Nebula clouds: two fractal noise layers tinted blue and violet.
nebula() { # <seed> <blur> <contrast> <color> <strength> <out>
    magick -size 1280x720 -seed "$1" plasma:fractal -blur "0x$2" -colorspace gray -auto-level \
        -sigmoidal-contrast "$3" -resize "${W}x${H}!" -blur 0x6 \
        \( -size 1x256 gradient:"#000000-$4" \) -clut -evaluate multiply "$5" "$6"
}
mkdir -p -- "${OUT}"

if want orbit || want nebula; then
    nebula 42 6 12,68% "${BLUE}" 0.45 n1.png
    nebula 5 4 14,75% "${VIOLET}" 0.35 n2.png

    # Stars: many faint pixels plus a few bright ones with a soft glow.
    magick -size "${W}x${H}" xc:black -seed 11 +noise Random -channel G -separate +channel \
        -threshold 99.93% stars1.png
    magick -size "${W}x${H}" xc:black -seed 23 +noise Random -channel G -separate +channel \
        -threshold 99.995% -morphology Dilate Disk:1.5 \
        \( +clone -blur 0x6 -evaluate multiply 2 \) -compose Screen -composite stars2.png

    magick -size "${W}x${H}" radial-gradient:'#0d1426-#030407' \
        n1.png -compose Screen -composite n2.png -compose Screen -composite \
        stars1.png -compose Screen -composite stars2.png -compose Screen -composite space.png

    # Mascot with a blue glow and an opaque backing for its closed areas (laptop).
    magick -background none -density 150 "${LOGO}/monos-mark.svg" -resize x1000 mark.png
    magick mark.png -channel A -blur 0x45 -evaluate multiply 0.9 +channel \
        -fill "${BLUE}" -colorize 100 glow.png
    magick mark.png -alpha extract -threshold 10% -morphology Dilate Disk:8 \
        -bordercolor black -border 2 -fill red -draw 'color 0,0 floodfill' -shave 2x2 \
        -fill black -opaque white -fill white +opaque red -fill black -opaque red \
        -morphology Erode Disk:8 -blur 0x1 \
        -background "${NIGHT}" -alpha shape backing.png
fi

if want orbit; then
    magick space.png \
        glow.png -gravity center -geometry +0+60 -compose Screen -composite \
        backing.png -gravity center -geometry +0+60 -compose Over -composite \
        mark.png -gravity center -geometry +0+60 -compose Over -composite \
        -quality 92 "${OUT}/monos-orbit.jpg"
fi

if want nebula; then
    magick -background none -density 150 "${LOGO}/monos-wordmark.svg" -resize x110 \
        -channel A -evaluate multiply 0.55 +channel wordmark.png
    magick space.png wordmark.png -gravity southeast -geometry +140+120 -compose Over -composite \
        -quality 92 "${OUT}/monos-nebula.jpg"
fi

# Daylight (monOS Light): the same nebula idea on the light palette. Pale
# blue and violet clouds multiplied onto a near-white gradient, sparse dots
# in brand blue and border gray, and the wordmark in the light text color.
if want daylight; then
    LIGHT_BG="#FCFCFC"     # light.ui.bg
    LIGHT_EDGE="#E4EAF3"   # between light.ui.surface2 and light.ui.border
    LIGHT_BLUE="#D5E4FC"   # tint of light.ui.selection
    LIGHT_VIOLET="#E8DFFB" # tint of brand violet
    LIGHT_FG="#1A1E27"     # light.ui.fg
    LIGHT_DOT="#9AA4B5"    # between light.ui.border and light.ui.muted

    cloud() { # <seed> <blur> <contrast> <color> <out>: white where empty
        magick -size 1280x720 -seed "$1" plasma:fractal -blur "0x$2" -colorspace gray -auto-level \
            -sigmoidal-contrast "$3" -resize "${W}x${H}!" -blur 0x6 \
            \( -size 1x256 gradient:"#FFFFFF-$4" \) -clut "$5"
    }
    cloud 42 6 12,68% "${LIGHT_BLUE}" d1.png
    cloud 5 4 14,75% "${LIGHT_VIOLET}" d2.png

    dots() { # <seed> <threshold> <color> <opacity> <dilate> <out>
        magick -size "${W}x${H}" xc:black -seed "$1" +noise Random -channel G -separate +channel \
            -threshold "$2" -morphology Dilate "Disk:$5" -blur 0x0.8 \
            -background "$3" -alpha shape -channel A -evaluate multiply "$4" +channel "$6"
    }
    dots 11 99.96% "${LIGHT_DOT}" 0.55 1 dots1.png
    dots 23 99.996% "${BLUE}" 0.45 2.5 dots2.png

    sed -e "s/#FCFCFC/${LIGHT_FG}/g" -- "${LOGO}/monos-wordmark.svg" >wordmark-dark.svg
    magick -background none -density 150 wordmark-dark.svg -resize x110 \
        -channel A -evaluate multiply 0.55 +channel wordmark-dark.png

    magick -size "${W}x${H}" radial-gradient:"${LIGHT_BG}-${LIGHT_EDGE}" \
        d1.png -compose Multiply -composite d2.png -compose Multiply -composite \
        dots1.png -compose Over -composite dots2.png -compose Over -composite \
        wordmark-dark.png -gravity southeast -geometry +140+120 -compose Over -composite \
        -quality 92 "${OUT}/monos-daylight.jpg"
fi

echo ":: Wrote:"
ls -lh -- "${OUT}"/monos-*.jpg
