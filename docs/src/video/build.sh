#!/usr/bin/env bash
set -euo pipefail
M="$(cd "$(dirname "$0")" && pwd)"; C="$M/cards"; O="$M/seg"; mkdir -p "$O"; rm -f "$O"/*.mp4
SHOW=~/Videos/showcase.mp4; INST=/home/deadlock/Files/Pictures/instalation_1.webm; TIL=/home/deadlock/Files/Pictures/tiling.webm
IMG="/home/deadlock/Documents/SISTEMAS OPERATIVOS/PROYECTO_2/website/images"
ENC=(-c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -r 30 -an)
n=0; next() { n=$((n+1)); NEXT=$(printf '%s/%02d.mp4' "$O" "$n"); }
fade() { local d=$1; echo "fade=t=in:st=0:d=0.4,fade=t=out:st=$(python3 -c "print(round($d-0.4,2))"):d=0.4"; }
card() { next; local f=$1 d=$2; ffmpeg -hide_banner -loglevel error -y -loop 1 -t "$d" -i "$C/$f.png" -vf "format=yuv420p,$(fade "$d")" "${ENC[@]}" "$NEXT"; }
# clip <src> <start> <dur-in-source> <speed> <caption>
clip() { next; local src=$1 ss=$2 dur=$3 sp=$4 cap=$5; local out; out=$(python3 -c "print(round($dur/$sp,2))")
  ffmpeg -hide_banner -loglevel error -y -loop 1 -t "$out" -i "$C/$cap.png" -ss "$ss" -t "$dur" -i "$src" \
    -filter_complex "[1:v]setpts=PTS/$sp,scale=1536:960,fps=30[v];[0:v][v]overlay=192:12:shortest=1,format=yuv420p,$(fade "$out")" "${ENC[@]}" -t "$out" "$NEXT"; }
still() { next; local img=$1 d=$2 cap=$3
  ffmpeg -hide_banner -loglevel error -y -loop 1 -t "$d" -i "$C/$cap.png" -loop 1 -t "$d" -i "$img" \
    -filter_complex "[1:v]scale=1536:960:force_original_aspect_ratio=decrease,pad=1536:960:(ow-iw)/2:(oh-ih)/2:color=0x0B0D12,fps=30[v];[0:v][v]overlay=192:12,format=yuv420p,$(fade "$d")" "${ENC[@]}" -t "$d" "$NEXT"; }
site() { next; local d=19
  ffmpeg -hide_banner -loglevel error -y -loop 1 -t "$d" -i "$C/c-sitio.png" -loop 1 -t "$d" -i "$M/site-full.png" \
    -filter_complex "[1:v]crop=1440:900:0:'if(lt(t,2),0,if(lt(t,10),(t-2)/8*12700,if(lt(t,13.5),12700,if(lt(t,15),12700+(t-13.5)/1.5*850,13550))))',scale=1536:960,fps=30[v];[0:v][v]overlay=192:12,format=yuv420p,$(fade "$d")" "${ENC[@]}" -t "$d" "$NEXT"; }

card 01-intro 4
card 02-problema 6
card 03-solucion 6
card 04-valor 6
card 05-visual 5
still "$IMG/sddm.webp" 4 c-login
clip "$SHOW" 184 24 1.6 c-temas
card 06-catalogo 6
still "$IMG/instalador-paquetes.webp" 5 c-paquetes
card 07-demo 3.5
clip "$SHOW" 17 16 1.3 c-escritorio
clip "$SHOW" 38 14 1.3 c-editores
clip "$SHOW" 64 12 1.3 c-yazi
clip "$SHOW" 94 8 1.2 c-btop
clip "$SHOW" 110 12 1.3 c-dolphin
clip "$SHOW" 152 12 1.3 c-obsidian
clip "$TIL" 3 38 2.5 c-tiling
card 08-instalacion 4
clip "$INST" 0 300 15 c-instalacion
card 09-disponibilidad 5
site
card 10-descarga 6
card 11-outro 6
printf "file '%s'\n" "$O"/*.mp4 > "$M/list.txt"
ffmpeg -hide_banner -loglevel error -y -f concat -safe 0 -i "$M/list.txt" -c copy "$M/video-only.mp4"
# Music: "Path Of The Fireflies" by AERØHEAD, CC BY-NC 3.0 (credited on the last card).
MUSIC="/home/deadlock/Downloads/AERØHEAD - Path Of The Fireflies.mp3"
D=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$M/video-only.mp4")
FO=$(python3 -c "print(round($D-4,2))")
ffmpeg -hide_banner -loglevel error -y -i "$M/video-only.mp4" -i "$MUSIC" \
  -filter_complex "[1:a]loudnorm=I=-16:TP=-1.5:LRA=11,afade=t=in:st=0:d=1.5,afade=t=out:st=$FO:d=4,apad[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -ar 48000 -t "$D" -movflags +faststart "$M/monOS-lanzamiento.mp4"
ffprobe -v error -show_entries format=duration -of csv=p=0 "$M/monOS-lanzamiento.mp4"
