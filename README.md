# Alpine Marmot · Starwatch

A night-meadow theme for [Omarchy](https://omarchy.org): a marmot watching the Milky Way, fireflies drifting through the grass. It includes more than colors and a wallpaper. The sky moves, and the lock screen, login intro, boot splash, mouse cursor and even your clicks all match.

![Desktop](previews/desktop.jpg)

![In use](previews/session.jpg)

| Live wallpaper | Login intro | Lock screen |
|---|---|---|
| ![Live wallpaper](previews/live-wallpaper.gif) | ![Intro](previews/intro.gif) | ![Lock screen](previews/lock.gif) |

**Cursors** and **click effects** (fireflies on left click, sparkles on right, a ripple on middle):

![Cursors](cursors/preview.png)

![Click effect](previews/clicks.gif)

**Boot splash** (LUKS password prompt):

![Boot splash](previews/boot-splash.jpg)

**Wallpapers**: Starwatch (animated), Meadow Sunset, Burrow Dawn, Larch Autumn:

![Wallpapers](previews/wallpapers.jpg)

## What's inside

| Piece | What it does |
|---|---|
| **Theme** (`colors.toml`, `backgrounds/`, `btop.theme`, `icons.theme`) | The "Starwatch" palette: navy sky, blue accent, firefly-cream text. The palette was pulled from the wallpaper with Aether and the reds/yellows were hand-tuned. Includes 4 wallpapers. |
| **Live wallpaper** ([standalone](https://github.com/prostratepossum/omarchy-starwatch-background)) | A GPU shader over the Starwatch wallpaper. Stars twinkle, fireflies drift and pulse in the grass, and a shooting star crosses now and then. Runs at 30 fps and pauses when a window is fullscreen. Other wallpapers stay static. |
| **Lock screen** ([standalone](https://github.com/prostratepossum/omarchy-starwatch-lock)) | Animated sky with a slow zoom, the marmot badge in a rotating ring, a greeting, a glowing clock, and a password pill with an aurora ring. Fireflies float around and every keystroke throws sparks. Wrong passwords shake red. |
| **Login intro** ([standalone](https://github.com/prostratepossum/omarchy-starwatch-intro)) | A ~5 s overlay once per boot. The sky fades in, fireflies gather into the badge, then an iris opens onto your desktop. It's click-through, so it never blocks you. |
| **Cursors** (`cursors/`) | A Starwatch XCursor theme: navy arrows with a cream outline and a firefly at the tip. Includes 14 shapes plus aliases, with an animated crescent-moon wait cursor. Anything not drawn falls back to Adwaita. Rebuild with `cursors/build.py`. |
| **Click effects** ([standalone](https://github.com/prostratepossum/omarchy-starwatch-clicks)) | A tiny burst wherever you click: fireflies for left, lavender sparkles for right, a glacier ripple for middle. Click-through, and skipped over fullscreen windows. Needs `python-evdev` and the `input` group (see below). |
| **Boot splash** (`plymouth-starwatch/`) | Animated Plymouth theme with twinkling stars, drifting fireflies, a shooting star and a floating badge. Password bullets are drawn as fireflies. Optional, and needs sudo. |
| **Login chime** (`sounds/`) | A soft synthesized night-meadow chime played at login. Optional. |
| **Terminal rice** (`extras/`) | Starship prompt, fastfetch marmot logo, lazygit, eza and fzf colors, and a transparent btop. Optional. |

## Install

Requires an up-to-date Omarchy (the Quickshell-based `omarchy-shell`).

```bash
git clone https://github.com/prostratepossum/omarchy-alpine-marmot-theme.git
cd omarchy-alpine-marmot-theme
./install.sh            # theme + cursors + live wallpaper, lock screen, intro, click effects
./install.sh --all      # ...plus terminal rice and login chime
```

Only want one of the animations? Each is also its own plugin: `omarchy plugin add https://github.com/prostratepossum/omarchy-starwatch-background --enable` (likewise `-lock`, `-intro`, `-clicks`).

Other options: `--dotfiles`, `--sound`, `--no-plugins`, `--no-cursors`. Any file the installer replaces is backed up next to the original as `*.bak.<timestamp>`.

**Just the colors and wallpapers?** Use `omarchy theme install https://github.com/prostratepossum/omarchy-alpine-marmot-theme.git`.

**Click effects setup:** the plugin reads mouse buttons through evdev, so it needs:

```bash
sudo pacman -S python-evdev
sudo usermod -aG input $USER   # then log out and back in
```

The helper only opens mouse-type devices and only reads button presses, never keyboards or movement. Note that the `input` group lets any program you run read input devices, so skip the click effects if that trade-off isn't for you (`omarchy plugin remove io.github.prostratepossum.starwatch-clicks`).

**Boot splash (optional):**

```bash
~/.config/omarchy/themes/alpine-marmot/plymouth-starwatch/install.sh           # install
~/.config/omarchy/themes/alpine-marmot/plymouth-starwatch/install.sh --revert  # back to stock
```

This rebuilds your initramfs. If the splash ever misbehaves, press **Esc** at boot for the plain text password prompt, then run `--revert`.

## Try it out

```bash
omarchy-shell -q intro play                  # replay the login intro
omarchy-shell lock previewInteractive        # preview the lock screen without locking (closes after 90 s)
omarchy-shell -q background toggleAnimation  # pause/resume the live wallpaper
omarchy-shell -q clicks test                 # play a click burst in the middle of the screen
omarchy-shell -q clicks toggle               # turn the click effects on/off
```

The live wallpaper costs about 8 W of GPU power and ~2% GPU busy on a Radeon RX 9070 XT. Turn it off with the toggle above if you're on battery.

## Uninstall

```bash
./install.sh --uninstall      # restores the stock Omarchy background + lock plugins and cursor
omarchy theme set <another-theme>
```

## Notes

- The keyboard lighting script in `extras/keyboard/` targets a Razer BlackWidow through OpenRGB. It's included as a reference and is not installed automatically.
- Shaders ship precompiled (`.qsb`). After editing `starwatch.frag`, rebuild with
  `/usr/lib/qt6/bin/qsb --glsl "100es,120,150" --hlsl 50 --msl 12 -o starwatch.frag.qsb starwatch.frag`.
- The background and lock plugins are forks of Omarchy's built-in `omarchy.background` and `omarchy.lock` (MIT).

## License

Code: MIT (see `LICENSE`). Artwork (wallpapers, badge, splash images, chime): free for personal use. Please don't resell it or use it in other products without asking.
