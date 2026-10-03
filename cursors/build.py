#!/usr/bin/python3
"""Build the Starwatch XCursor theme.

Every cursor is drawn as SVG on a 32-unit canvas, rendered with rsvg-convert at
each size in SIZES, and packed into XCursor files (premultiplied ARGB). Shapes
not drawn here fall back to Adwaita through index.theme.

    ./build.py            -> ./Starwatch/
    ./build.py --install  -> also copies to ~/.local/share/icons/Starwatch
"""
import io
import math
import shutil
import struct
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
OUT = HERE / "Starwatch"
SIZES = (24, 32, 48, 64)

NAVY = "#0b1638"
NAVY_LIGHT = "#1f2d5c"
CREAM = "#e8e3a0"
FIREFLY = "#e3dc5c"
FIREFLY_CORE = "#fffbd0"
NEBULA = "#9d8fe6"
ROSE = "#e0848f"

DEFS = f"""
<defs>
  <linearGradient id="body" x1="0" y1="0" x2="0.6" y2="1">
    <stop offset="0" stop-color="{NAVY_LIGHT}"/>
    <stop offset="1" stop-color="{NAVY}"/>
  </linearGradient>
  <radialGradient id="fly">
    <stop offset="0" stop-color="{FIREFLY_CORE}"/>
    <stop offset="0.35" stop-color="{FIREFLY}"/>
    <stop offset="1" stop-color="{FIREFLY}" stop-opacity="0"/>
  </radialGradient>
  <filter id="shadow" x="-50%" y="-50%" width="200%" height="200%">
    <feDropShadow dx="0.6" dy="0.9" stdDeviation="0.8" flood-color="#000" flood-opacity="0.45"/>
  </filter>
</defs>
"""


def svg(body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">{DEFS}{body}</svg>'


def firefly(x, y, r=3.2, glow=1.0):
    """Soft glow blob with a bright core."""
    return (f'<circle cx="{x:.2f}" cy="{y:.2f}" r="{r * glow:.2f}" fill="url(#fly)" opacity="{0.85 * glow:.2f}"/>'
            f'<circle cx="{x:.2f}" cy="{y:.2f}" r="{r * 0.28:.2f}" fill="{FIREFLY_CORE}"/>')


def star4(x, y, r, color=CREAM, opacity=1.0):
    """Four-point sparkle, like the ✦ in the prompt."""
    k = r * 0.28
    d = (f"M{x},{y - r} Q{x + k},{y - k} {x + r},{y} Q{x + k},{y + k} {x},{y + r} "
         f"Q{x - k},{y + k} {x - r},{y} Q{x - k},{y - k} {x},{y - r} Z")
    return f'<path d="{d}" fill="{color}" opacity="{opacity:.2f}"/>'


ARROW = "M4,3 L4,24.5 L9.4,19.6 L12.9,27.6 L16.4,26.1 L12.9,18.4 L20.2,18.4 Z"


def arrow(extra=""):
    return svg(f'<g filter="url(#shadow)"><path d="{ARROW}" fill="url(#body)" stroke="{CREAM}" '
               f'stroke-width="1.35" stroke-linejoin="round"/></g>'
               f'{firefly(4.6, 4.2, 2.6)}{extra}')


def double_arrow(angle):
    """Resize arrow along the x axis, rotated by `angle` degrees about the centre."""
    d = ("M4,16 L10,10.5 L10,13.9 L22,13.9 L22,10.5 L28,16 L22,21.5 L22,18.1 "
         "L10,18.1 L10,21.5 Z")
    return svg(f'<g transform="rotate({angle} 16 16)" filter="url(#shadow)"><path d="{d}" '
               f'fill="url(#body)" stroke="{CREAM}" stroke-width="1.2" stroke-linejoin="round"/></g>'
               f'{firefly(16, 16, 2.4)}')


def move():
    d = ("M16,3 L20.5,8 L17.6,8 L17.6,14.4 L24,14.4 L24,11.5 L29,16 L24,20.5 L24,17.6 "
         "L17.6,17.6 L17.6,24 L20.5,24 L16,29 L11.5,24 L14.4,24 L14.4,17.6 L8,17.6 "
         "L8,20.5 L3,16 L8,11.5 L8,14.4 L14.4,14.4 L14.4,8 L11.5,8 Z")
    return svg(f'<g filter="url(#shadow)"><path d="{d}" fill="url(#body)" stroke="{CREAM}" '
               f'stroke-width="1.1" stroke-linejoin="round"/></g>{firefly(16, 16, 3.0)}')


def hand(closed=False):
    """Open palm (grab) or a star cupped in a closed hand (grabbing): drawn as a
    rounded mitten so it stays legible at 24 px."""
    if closed:
        d = "M9,14 Q9,11 12,11 L21,11 Q24,11 24,14 L24,21 Q24,27 18,27 L14,27 Q9,27 9,22 Z"
    else:
        d = ("M8.5,15 Q8.5,12.5 10.8,12.5 L10.8,7 Q10.8,5 12.8,5 Q14.8,5 14.8,7 L14.8,11 "
             "L14.8,5.5 Q14.8,3.5 16.8,3.5 Q18.8,3.5 18.8,5.5 L18.8,11 L18.8,6.5 Q18.8,4.5 20.8,4.5 "
             "Q22.8,4.5 22.8,6.5 L22.8,20 Q22.8,27.5 16.5,27.5 L14.5,27.5 Q10.5,27.5 8.5,22 Z")
    sparkle = star4(16, 19, 3.6, FIREFLY) if closed else ""
    return svg(f'<g filter="url(#shadow)"><path d="{d}" fill="url(#body)" stroke="{CREAM}" '
               f'stroke-width="1.2" stroke-linejoin="round"/></g>{sparkle}')


def text_beam():
    d = "M11,4 Q16,4 16,7 Q16,4 21,4 M16,7 L16,25 M11,28 Q16,28 16,25 Q16,28 21,28 M13,16 L19,16"
    return svg(f'<path d="{d}" fill="none" stroke="{NAVY}" stroke-width="3.6" stroke-linecap="round"/>'
               f'<path d="{d}" fill="none" stroke="{CREAM}" stroke-width="1.6" stroke-linecap="round"/>'
               f'{firefly(16, 16, 2.2, 0.8)}')


def crosshair():
    d = "M16,3 L16,12 M16,20 L16,29 M3,16 L12,16 M20,16 L29,16"
    return svg(f'<path d="{d}" stroke="{NAVY}" stroke-width="3.4" stroke-linecap="round"/>'
               f'<path d="{d}" stroke="{CREAM}" stroke-width="1.4" stroke-linecap="round"/>'
               f'{firefly(16, 16, 3.0)}')


def not_allowed():
    return svg(f'<g filter="url(#shadow)"><circle cx="16" cy="16" r="10" fill="{NAVY}" fill-opacity="0.6" '
               f'stroke="{ROSE}" stroke-width="2.6"/>'
               f'<path d="M9,23 L23,9" stroke="{ROSE}" stroke-width="2.6" stroke-linecap="round"/></g>')


def moon(frame, frames):
    """Busy cursor: crescent moon, a firefly orbiting it, twinkling stars."""
    a = 2 * math.pi * frame / frames
    fx, fy = 16 + 11 * math.cos(a), 16 + 11 * math.sin(a)
    tw = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(a * 2))
    tw2 = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(a * 2 + 2.1))
    crescent = "M19.5,8.2 A8.4,8.4 0 1 0 23.8,21.5 A6.6,6.6 0 1 1 19.5,8.2 Z"
    trail = "".join(firefly(16 + 11 * math.cos(a - i * 0.28), 16 + 11 * math.sin(a - i * 0.28),
                            1.8, 0.55 - i * 0.13) for i in (3, 2, 1))
    return svg(f'<g filter="url(#shadow)"><path d="{crescent}" fill="{CREAM}" stroke="{NAVY}" '
               f'stroke-width="0.9"/></g>'
               f'{star4(24.5, 7.5, 2.4, CREAM, tw)}{star4(7, 25, 1.8, NEBULA, tw2)}'
               f'{trail}{firefly(fx, fy, 3.2)}')


def progress(frame, frames):
    """Arrow with a firefly circling beside it."""
    a = 2 * math.pi * frame / frames
    fx, fy = 22.5 + 5 * math.cos(a), 23 + 5 * math.sin(a)
    ring = f'<circle cx="22.5" cy="23" r="5" fill="none" stroke="{NEBULA}" stroke-opacity="0.35" stroke-width="0.8"/>'
    return arrow(ring + firefly(fx, fy, 2.6))


def pointer():
    """Link cursor: the arrow with a sparkle that says 'clickable'."""
    return arrow(star4(22.5, 9, 4.2, FIREFLY) + star4(26.5, 15.5, 1.8, CREAM, 0.8))


# name -> (frames: list of svg strings, hotspot in 32-unit space, frame delay ms)
ANIM = 16
CURSORS = {
    "default": ([arrow()], (4, 3), 0),
    "pointer": ([pointer()], (4, 3), 0),
    "text": ([text_beam()], (16, 16), 0),
    "crosshair": ([crosshair()], (16, 16), 0),
    "not-allowed": ([not_allowed()], (16, 16), 0),
    "move": ([move()], (16, 16), 0),
    "grab": ([hand(False)], (16, 14), 0),
    "grabbing": ([hand(True)], (16, 16), 0),
    "ew-resize": ([double_arrow(0)], (16, 16), 0),
    "ns-resize": ([double_arrow(90)], (16, 16), 0),
    "nwse-resize": ([double_arrow(45)], (16, 16), 0),
    "nesw-resize": ([double_arrow(-45)], (16, 16), 0),
    "wait": ([moon(i, ANIM) for i in range(ANIM)], (16, 16), 55),
    "progress": ([progress(i, ANIM) for i in range(ANIM)], (4, 3), 55),
}

# XCursor/CSS aliases so older toolkits find the same art.
ALIASES = {
    "default": ["left_ptr", "arrow", "top_left_arrow", "context-menu", "copy", "alias"],
    "pointer": ["hand1", "hand2", "pointing_hand", "e29285e634086352946a0e7090d73106",
                "9d800788f1b08800ae810202380a0822"],
    "text": ["xterm", "ibeam", "vertical-text"],
    "crosshair": ["cross", "tcross", "cell", "color-picker"],
    "not-allowed": ["no-drop", "forbidden", "circle", "crossed_circle", "03b6e0fcb3499374a867c041f52298f0"],
    "move": ["fleur", "all-scroll", "size_all", "all-resize"],
    "grab": ["openhand", "5aca4d189052212118709018842178c0"],
    "grabbing": ["closedhand", "dnd-move", "dnd-none", "208530c400c041818281048008011002"],
    "ew-resize": ["col-resize", "sb_h_double_arrow", "h_double_arrow", "size_hor", "e-resize",
                  "w-resize", "left_side", "right_side", "split_h", "14fef782d02440884392942c11205230"],
    "ns-resize": ["row-resize", "sb_v_double_arrow", "v_double_arrow", "size_ver", "n-resize",
                  "s-resize", "top_side", "bottom_side", "split_v", "2870a09082c103050810ffdffffe0204"],
    "nwse-resize": ["size_fdiag", "bd_double_arrow", "nw-resize", "se-resize", "top_left_corner",
                    "bottom_right_corner", "c7088f0f3e6c8088236ef8e1e3e70000"],
    "nesw-resize": ["size_bdiag", "fd_double_arrow", "ne-resize", "sw-resize", "top_right_corner",
                    "bottom_left_corner", "fcf1c3c7cd4491d801f1e1c78f100000"],
    "wait": ["watch", "clock"],
    "progress": ["left_ptr_watch", "half-busy", "00000000000000020006000e7e9ffc3f",
                 "08e8e1c95fe2fc01f976f1e063a24ccd", "3ecb610c1bf2410f44200f48c40d3599"],
}


def render(svg_text, size):
    png = subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size)],
                         input=svg_text.encode(), capture_output=True, check=True).stdout
    return Image.open(io.BytesIO(png)).convert("RGBA")


def xcursor(frames, hotspot, delay):
    """Pack rendered frames into the XCursor binary format."""
    images = []
    for size in SIZES:
        hx, hy = (round(c * size / 32) for c in hotspot)
        for svg_text in frames:
            img = render(svg_text, size)
            rgba = np.asarray(img, dtype=np.uint32)
            a = rgba[..., 3]
            argb = (a << 24) | (rgba[..., 0] * a // 255 << 16) | (rgba[..., 1] * a // 255 << 8) | (rgba[..., 2] * a // 255)
            images.append((size, size, size, hx, hy, delay, argb.astype("<u4").tobytes()))
    header = 16
    toc = 12 * len(images)
    out = bytearray(struct.pack("<4sIII", b"Xcur", header, 0x10000, len(images)))
    pos = header + toc
    for nominal, w, h, *_rest, px in images:
        out += struct.pack("<III", 0xFFFD0002, nominal, pos)
        pos += 36 + len(px)
    for nominal, w, h, hx, hy, dl, px in images:
        out += struct.pack("<IIIIIIIII", 36, 0xFFFD0002, nominal, 1, w, h, hx, hy, dl)
        out += px
    return bytes(out)


def main():
    if OUT.exists():
        shutil.rmtree(OUT)
    cdir = OUT / "cursors"
    cdir.mkdir(parents=True)
    for name, (frames, hotspot, delay) in CURSORS.items():
        (cdir / name).write_bytes(xcursor(frames, hotspot, delay))
        for alias in ALIASES.get(name, []):
            link = cdir / alias
            if not link.exists():
                link.symlink_to(name)
    (OUT / "index.theme").write_text(
        "[Icon Theme]\nName=Starwatch\nComment=Alpine Marmot night-meadow cursors: "
        "navy and firefly-cream, with a firefly at the tip\nInherits=Adwaita\n")
    (OUT / "cursor.theme").write_text("[Icon Theme]\nInherits=Starwatch\n")

    # Contact sheet for previews.
    names = list(CURSORS)
    sheet = Image.new("RGBA", (len(names) * 80, 96), (3, 14, 42, 255))
    for i, name in enumerate(names):
        sheet.alpha_composite(render(CURSORS[name][0][0], 64), (i * 80 + 8, 16))
    sheet.save(HERE / "preview.png")

    if "--install" in sys.argv:
        dest = Path.home() / ".local/share/icons/Starwatch"
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(OUT, dest, symlinks=True)
        print(f"installed to {dest}")
    print(f"built {len(CURSORS)} cursors, {sum(len(v) for v in ALIASES.values())} aliases")


if __name__ == "__main__":
    main()
