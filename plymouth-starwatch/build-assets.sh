#!/bin/bash
# Regenerates the Starwatch plymouth assets from the theme's wallpaper/badge.
set -euo pipefail
cd "$(dirname "$0")"

wallpaper=~/.config/omarchy/themes/alpine-marmot/backgrounds/0-starwatch.jpg
[[ -f $wallpaper ]] || wallpaper=~/.local/state/omarchy/current/theme/backgrounds/0-starwatch.jpg

magick "$wallpaper" -resize 1920x1080 -define png:compression-level=9 background.png
cp ~/Pictures/marmotmonk-art/alpine/badge_starwatch.png badge.png

# Soft radial glows for stars and fireflies (bullets reuse the firefly).
magick -size 32x32 radial-gradient:'rgba(255,255,255,1)-rgba(210,225,255,0)' -channel A -evaluate pow 1.8 +channel star.png
magick -size 48x48 radial-gradient:'rgba(240,234,128,1)-rgba(227,220,92,0)' -channel A -evaluate pow 1.6 +channel firefly.png
cp firefly.png bullet.png

# Breathing halo ring behind the badge.
magick -size 400x400 xc:none -fill none -stroke 'rgba(134,157,255,0.9)' -strokewidth 14 \
  -draw "circle 200,200 200,78" -blur 0x18 halo.png

# Password pill and progress bar.
magick -size 440x62 xc:none -fill 'rgba(3,14,42,0.82)' -stroke '#647cd6' -strokewidth 2 \
  -draw "roundrectangle 1,1 438,60 30,30" entry.png
magick -size 440x6 xc:none -fill 'rgba(28,38,63,0.9)' -draw "roundrectangle 0,0 439,5 3,3" progress_box.png
magick -size 440x6 gradient:'#647cd6-#e3dc5c' -rotate 90 -resize 440x6\! \
  \( -size 440x6 xc:none -fill white -draw "roundrectangle 0,0 439,5 3,3" \) \
  -compose CopyOpacity -composite progress_bar.png

# Shooting star: head bottom-left, tail up-right (travels down-left).
/usr/bin/python3 - <<'EOF'
import numpy as np, subprocess
w, h = 380, 200
d = np.array([-2.0, 1.0]); d /= np.linalg.norm(d)
hx, hy, L = 20.0, h - 20.0, 360.0
yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
px, py = xx - hx, yy - hy
along = -(px * d[0] + py * d[1])
across = np.abs(px * d[1] - py * d[0])
t = np.clip(along / L, 0, 1)
width = 0.8 + 2.2 * (1 - t)
a = np.where((along >= 0) & (along <= L), (1 - t) ** 1.5 * np.exp(-(across / width) ** 2), 0)
a = np.clip(a + np.exp(-(px ** 2 + py ** 2) / 18.0), 0, 1)
rgba = np.zeros((h, w, 4), np.uint8)
rgba[..., 0], rgba[..., 1], rgba[..., 2] = 235, 242, 255
rgba[..., 3] = (a * 255).astype(np.uint8)
subprocess.run(["magick", "-size", f"{w}x{h}", "-depth", "8", "rgba:-", "streak.png"],
               input=rgba.tobytes(), check=True)
EOF

ls -la *.png
