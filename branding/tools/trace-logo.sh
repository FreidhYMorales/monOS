#!/usr/bin/env bash
# Vectorize the raster monOS logo into real SVG files.
#
# Usage: ./branding/tools/trace-logo.sh <logo.png|logo.svg-with-embedded-png>
#
# The source artwork is a 1254x1254 raster (white line art, brand blue accents,
# a gray floor shadow, black background). Each color is traced separately with
# potrace at 2x resolution; the background is dropped (transparent output).
# The wordmark's lowercase "s" is replaced by a geometric capital "S" drawn in
# the same squared, rounded style, so the wordmark reads "monOS".
#
# Requires: imagemagick (magick), potrace.
set -euo pipefail

SRC="${1:?usage: $0 <logo.png|logo.svg>}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$(dirname -- "${SCRIPT_DIR}")/logo"
TMP="$(mktemp -d)"
trap 'rm -rf -- "${TMP}"' EXIT

for tool in magick potrace; do
    command -v "${tool}" >/dev/null 2>&1 || { echo "error: '${tool}' not found" >&2; exit 1; }
done

# Brand palette (sampled from the source artwork).
WHITE="#FCFCFC"
BLUE="#0C6BFA"
SHADOW="#4C4D4F"
LAPTOP_EDGE="#434247"   # from the first version of the artwork
BADGE="#0B0D12"

# Accept an SVG that only wraps an embedded PNG.
if [[ "${SRC}" == *.svg ]]; then
    rg -o 'base64,[A-Za-z0-9+/=]+' "${SRC}" | head -1 | cut -d, -f2 | base64 -d >"${TMP}/src.png"
else
    cp -- "${SRC}" "${TMP}/src.png"
fi
[[ "$(magick identify -format '%wx%h' "${TMP}/src.png")" == "1254x1254" ]] ||
    { echo "error: expected a 1254x1254 source image" >&2; exit 1; }

# Layout of the source (1x pixels): mascot above y=880, wordmark below.
# Wordmark columns (word space): m 0-187, o 208-347, n 372-499, O 520-683, s 704-835.
SPLIT_Y=1760        # 880 * 2
S_X=1812            # (212 + 694) * 2, gap between O and s

magick "${TMP}/src.png" -filter Lanczos -resize 200% "${TMP}/src2x.png"

# Layer masks (white = shape).
magick "${TMP}/src2x.png" -fx 'min(min(u.r,u.g),u.b)' -threshold 55% "${TMP}/white.png"
magick "${TMP}/src2x.png" -fx 'u.b-u.r' -threshold 45% "${TMP}/blue.png"
magick "${TMP}/src2x.png" \
    -fx 'mx=max(max(u.r,u.g),u.b); mn=min(min(u.r,u.g),u.b); (mx>0.18 && mx<0.42 && (mx-mn)<0.08) ? 1 : 0' \
    -morphology Open Disk:4 "${TMP}/gray.png"

# Split masks into mascot / wordmark regions; drop the lowercase "s".
region() { # <in> <out> <draw-args...>: black out the given rectangles
    local in="$1" out="$2"; shift 2
    magick "${in}" -fill black "$@" "${out}"
}
region "${TMP}/white.png" "${TMP}/white-mascot.png" -draw "rectangle 0,${SPLIT_Y} 2508,2508"
region "${TMP}/white.png" "${TMP}/white-word.png"   -draw "rectangle 0,0 2508,${SPLIT_Y}"
region "${TMP}/blue.png"  "${TMP}/blue-mascot.png"  -draw "rectangle 0,${SPLIT_Y} 2508,2508"
region "${TMP}/blue.png"  "${TMP}/blue-word.png"    -draw "rectangle 0,0 2508,${SPLIT_Y}" \
    -draw "rectangle ${S_X},${SPLIT_Y} 2508,2508"
cp -- "${TMP}/gray.png" "${TMP}/gray-mascot.png"

# Laptop frame: the right and bottom edges are the gray "thickness" of the
# screen (as in the original artwork). They are the white pixels on the
# bottom-right side of the line from the frame's top-right corner (1020,570)
# to its bottom-left corner (679,778), above the feet (y < 789) — 1x coords.
LAPTOP_EDGE_REGION="polygon 2108,1098 2120,1098 2120,1578 1322,1578"
magick "${TMP}/white-mascot.png" \
    \( -size 2508x2508 xc:black -fill white -draw "${LAPTOP_EDGE_REGION}" \) \
    -compose Multiply -composite "${TMP}/laptop-edge.png"
magick "${TMP}/white-mascot.png" -fill black -draw "${LAPTOP_EDGE_REGION}" "${TMP}/white-mascot.png"

# Trace each mask; keep only the <path> elements (potrace coordinates are
# 10x and Y-flipped, handled by the shared transform below).
trace() { # <name> -> prints the path elements
    magick "${TMP}/$1.png" -negate "${TMP}/$1.pbm"
    potrace -b svg -t 8 -a 1.0 -O 0.4 -o "${TMP}/$1.svg" "${TMP}/$1.pbm"
    tr '\n' ' ' <"${TMP}/$1.svg" | rg -o '<path d="[^"]*"/>'
}
POTRACE_TF='translate(0,2508) scale(0.1,-0.1)'

layer() { # <name> <fill>
    printf '<g fill="%s" transform="%s">\n%s\n</g>\n' "$2" "${POTRACE_TF}" "$(trace "$1")"
}

MASCOT="$(layer gray-mascot "${SHADOW}")
$(layer white-mascot "${WHITE}")
$(layer laptop-edge "${LAPTOP_EDGE}")
$(layer blue-mascot "${BLUE}")"

# Wordmark in source "word space": origin (212,911) at 1x, cap height 149,
# stroke ~35. The capital S centerline mirrors the lowercase s construction.
S_PATH='M854 17.5H743.5A22 22 0 0 0 721.5 39.5V52.5A22 22 0 0 0 743.5 74.5H814.5A22 22 0 0 1 836.5 96.5V109.5A22 22 0 0 1 814.5 131.5H704'
WORD="$(layer white-word "${WHITE}")
$(layer blue-word "${BLUE}")
<path d=\"${S_PATH}\" transform=\"translate(424 1822) scale(2)\" fill=\"none\" stroke=\"${BLUE}\" stroke-width=\"35\"/>"

# The S is wider than the s: shift the wordmark to stay centered on the mascot.
WORD_SHIFT=-17

mkdir -p -- "${OUT_DIR}"

svg() { # <file> <viewBox> <title> <body>
    printf '<svg xmlns="http://www.w3.org/2000/svg" viewBox="%s" role="img">\n<title>%s</title>\n%s\n</svg>\n' \
        "$2" "$3" "$4" >"${OUT_DIR}/$1"
}

# Full logo (for dark backgrounds): mascot + wordmark.
svg monos-logo.svg "300 280 1922 1920" "monOS" \
    "${MASCOT}
<g transform=\"translate(${WORD_SHIFT} 0)\">
${WORD}
</g>"

# Mascot only (for dark backgrounds).
svg monos-mark.svg "400 320 1680 1480" "monOS" "${MASCOT}"

# Wordmark only (for dark backgrounds).
svg monos-wordmark.svg "350 1770 1822 400" "monOS" \
    "<g transform=\"translate(${WORD_SHIFT} 0)\">
${WORD}
</g>"

# App icon: mascot on a dark rounded badge; readable on any background.
svg monos-icon.svg "0 0 2048 2048" "monOS" \
    "<rect width=\"2048\" height=\"2048\" rx=\"440\" fill=\"${BADGE}\"/>
<g transform=\"translate(1024 1024) scale(0.85) translate(-1261 -1053)\">
${MASCOT}
</g>"

# Small icon (16-48 px): only the head (2x bbox 738-1746 x 352-1140), which stays legible at tiny sizes.
svg monos-icon-small.svg "0 0 2048 2048" "monOS" \
    "<rect width=\"2048\" height=\"2048\" rx=\"440\" fill=\"${BADGE}\"/>
<defs><clipPath id=\"head\"><ellipse cx=\"1250\" cy=\"745\" rx=\"515\" ry=\"392\"/></clipPath></defs>
<g transform=\"translate(1024 1024) scale(1.42) translate(-1250 -700)\">
<g clip-path=\"url(#head)\">
${MASCOT}
</g>
</g>"

echo ":: Wrote:"
ls -lh -- "${OUT_DIR}"/*.svg
