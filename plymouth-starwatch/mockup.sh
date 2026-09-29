#!/bin/bash
# Static mockup of one Starwatch splash frame (password prompt, 8 bullets).
# Mirrors the layout math in starwatch.script. Never run plymouthd live.
set -euo pipefail
cd "$(dirname "$0")"
W=${1:-2560}; H=${2:-1440}; out=${3:-mockup.png}

badge=$(( H * 16 / 100 )); (( badge < 120 )) && badge=120
halo=$(( badge * 16 / 10 ))
bx=$(( W / 2 - badge / 2 )); by=$(( H * 40 / 100 - badge / 2 ))
hx=$(( W / 2 - halo / 2 )); hy=$(( by + badge / 2 - halo / 2 ))
ex=$(( W / 2 - 220 )); ey=$(( by + badge + 60 ))

args=(background.png -resize "${W}x${H}^" -gravity center -extent "${W}x${H}" -gravity northwest)
RANDOM=29
for i in $(seq 70); do
  s=$(( 5 + RANDOM % 8 )); x=$(( RANDOM % W )); y=$(( RANDOM % (H * 30 / 100) ))
  args+=( \( star.png -resize "${s}x${s}" -channel A -evaluate multiply 0.$(( 3 + RANDOM % 6 )) +channel \) -geometry "+$x+$y" -composite )
done
for i in $(seq 28); do
  s=$(( 14 + RANDOM % 14 )); x=$(( RANDOM % W )); y=$(( H * 62 / 100 + RANDOM % (H * 36 / 100) ))
  args+=( \( firefly.png -resize "${s}x${s}" -channel A -evaluate multiply 0.$(( 3 + RANDOM % 7 )) +channel \) -geometry "+$x+$y" -composite )
done
args+=( streak.png -geometry "+$(( W * 55 / 100 ))+$(( H * 6 / 100 ))" -composite )
args+=( \( halo.png -resize "${halo}x${halo}" -channel A -evaluate multiply 0.8 +channel \) -geometry "+$hx+$hy" -composite )
args+=( \( badge.png -resize "${badge}x${badge}" \) -geometry "+$bx+$by" -composite )
args+=( entry.png -geometry "+$ex+$ey" -composite )
n=8; row=$(( n * 12 + (n - 1) * 8 )); sx=$(( W / 2 - row / 2 )); sy=$(( ey + 31 - 6 ))
for i in $(seq 0 $(( n - 1 ))); do
  args+=( \( bullet.png -resize 12x12 \) -geometry "+$(( sx + i * 20 ))+$sy" -composite )
done
magick "${args[@]}" "$out"
echo "$out"
