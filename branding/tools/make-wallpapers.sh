#!/usr/bin/env bash
# Generate the procedural monOS space wallpapers (3840x2160, brand palette).
#
# Usage: ./branding/tools/make-wallpapers.sh [orbit] [nebula] [daylight] [astronaut]
#
# Outputs branding/wallpapers/monos-orbit.jpg (glowing mascot),
# branding/wallpapers/monos-nebula.jpg (clean nebula + small wordmark),
# branding/wallpapers/monos-daylight.jpg (light nebula for monOS Light) and
# branding/wallpapers/monos-astronaut{,-light}.jpg (line-art scene from
# branding/wallpapers/src/astronaut.svg over the dark and light backgrounds).
# Without arguments all of them are rendered. Seeds are fixed, so the output
# is reproducible. Requires: imagemagick; resvg for the SVG scenes.
set -euo pipefail

WANT=("$@")
[[ ${#WANT[@]} -gt 0 ]] || WANT=(orbit nebula daylight astronaut)
want() { [[ " ${WANT[*]} " == *" $1 "* ]]; }

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BRANDING="$(dirname -- "${SCRIPT_DIR}")"
LOGO="${BRANDING}/logo"
OUT="${BRANDING}/wallpapers"
SRC="${OUT}/src"
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

if want orbit || want nebula || want astronaut; then
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
fi

if want orbit; then
    # Mascot with a blue glow and an opaque backing for its closed areas (laptop).
    magick -background none -density 150 "${LOGO}/monos-mark.svg" -resize x1000 mark.png
    magick mark.png -channel A -blur 0x45 -evaluate multiply 0.9 +channel \
        -fill "${BLUE}" -colorize 100 glow.png
    magick mark.png -alpha extract -threshold 10% -morphology Dilate Disk:8 \
        -bordercolor black -border 2 -fill red -draw 'color 0,0 floodfill' -shave 2x2 \
        -fill black -opaque white -fill white +opaque red -fill black -opaque red \
        -morphology Erode Disk:8 -blur 0x1 \
        -background "${NIGHT}" -alpha shape backing.png
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
if want daylight || want astronaut; then
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

    magick -size "${W}x${H}" radial-gradient:"${LIGHT_BG}-${LIGHT_EDGE}" \
        d1.png -compose Multiply -composite d2.png -compose Multiply -composite \
        dots1.png -compose Over -composite dots2.png -compose Over -composite day.png
fi

if want daylight; then
    sed -e "s/#FCFCFC/${LIGHT_FG}/g" -- "${LOGO}/monos-wordmark.svg" >wordmark-dark.svg
    magick -background none -density 150 wordmark-dark.svg -resize x110 \
        -channel A -evaluate multiply 0.55 +channel wordmark-dark.png
    magick day.png wordmark-dark.png -gravity southeast -geometry +140+120 -compose Over -composite \
        -quality 92 "${OUT}/monos-daylight.jpg"
fi

# Astronaut: SVG line-art scene (src/astronaut.svg) rendered with resvg and
# composed over the dark space and the daylight backgrounds. The mascot is the
# logo without its floor shadow (first <g>, it floats here). The light variant
# swaps the scene's color tokens: line art -> light.ui.fg, night fill ->
# light.ui.bg, glass highlights -> brand blue, laptop edge -> light.ui.muted,
# and the blue halo/glass tints (class="tint") drop to 40% opacity.
if want astronaut; then
    command -v resvg >/dev/null 2>&1 || { echo "error: 'resvg' not found" >&2; exit 1; }
    tr '\n' '\v' <"${LOGO}/monos-mark.svg" | sed -e 's|<g fill="#4C4D4F"[^>]*>[^<]*<path[^>]*/>[^<]*</g>||' |
        tr '\v' '\n' >mark-float.svg
    sed -e 's|href="../../logo/monos-mark.svg"|href="mark-float.svg"|' -- "${SRC}/astronaut.svg" >astronaut.svg
    # Light mascot: it must read like the logo, not its negative (a dark face
    # with light eyes). Layers, bottom to top:
    #  1. the white layer's outer contours (first subpath of each path, which
    #     closes the eye and nostril holes) in light.ui.fg: all the line art;
    #  2. masked to the layer's wide areas (face, ears, hands, feet): the layer
    #     itself in light.ui.bg plus its outer contour stroked in light.ui.fg, so
    #     those areas are light with a dark outline and dark eyes, as in the
    #     logo. The mask is a morphological opening of the layer (blur +
    #     threshold, a round kernel) of the outer contours (eye holes closed,
    #     so the thin rim beside an eye stays in) that drops line-art strokes.
    tr '\n' '\v' <mark-float.svg >mark-float.flat
    white_g="$(rg -o '<g fill="#FCFCFC".*?</g>' mark-float.flat)"
    lines_g="$(sed -E -e "s/#FCFCFC/${LIGHT_FG}/" -e 's/(<path d="[^z"]*z)[^"]*"/\1"/g' <<<"${white_g}")"
    fill_g="${white_g/\"#FCFCFC\"/\"${LIGHT_BG}\"}"
    edge_g="${lines_g/fill=\"${LIGHT_FG}\"/fill=\"none\" stroke=\"${LIGHT_FG}\" stroke-width=\"300\" stroke-linejoin=\"round\"}"
    step() { # <stdDeviation> <threshold>: blur the alpha, then threshold it
        defs+="<feGaussianBlur stdDeviation=\"$1\"/><feComponentTransfer>"
        defs+="<feFuncA type=\"linear\" slope=\"25\" intercept=\"$(awk "BEGIN{print 0.5-25*$2}")\"/>"
        defs+='</feComponentTransfer>'
    }
    defs='<defs><filter id="open" x="0" y="0" width="1" height="1">'
    defs+='<feFlood flood-color="#FFF"/><feComposite in2="SourceAlpha" operator="in"/>'
    step 12 0.97 # erode ~23: strokes narrower than ~50 vanish
    step 12 0.03 # dilate ~23: the wide areas come back
    defs+='</filter><mask id="wide" mask-type="alpha" maskUnits="userSpaceOnUse" x="400" y="320" width="1680" height="1480">'
    defs+="<g filter=\"url(#open)\">${lines_g}</g></mask></defs>"
    flat="$(<mark-float.flat)"
    flat="${flat/"${white_g}"/${lines_g}<g mask=\"url(#wide)\">${fill_g}${edge_g}</g>}"
    flat="${flat/<\/title>/</title>${defs}}"
    tr '\v' '\n' <<<"${flat}" | sed -e 's/#434247/#5E6778/g' >mark-float-light.svg
    sed -e "s/#FCFCFC/${LIGHT_FG}/g; s/#05070C/${LIGHT_BG}/g; s/#FFFFFF/${BLUE}/g" \
        -e 's/\(class="tint" .*\) opacity="1"/\1 opacity="0.4"/' \
        -e 's|href="mark-float.svg"|href="mark-float-light.svg"|' astronaut.svg >astronaut-light.svg

    resvg --resources-dir . astronaut.svg astronaut.png
    resvg --resources-dir . astronaut-light.svg astronaut-light.png
    magick space.png astronaut.png -compose Over -composite -quality 92 "${OUT}/monos-astronaut.jpg"
    magick day.png astronaut-light.png -compose Over -composite -quality 92 "${OUT}/monos-astronaut-light.jpg"
fi

echo ":: Wrote:"
ls -lh -- "${OUT}"/monos-*.jpg
