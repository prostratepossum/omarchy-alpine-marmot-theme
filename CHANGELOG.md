# Changelog

## 1.2.0

- The live wallpaper, lock screen, login intro and click effects now come from [Omarchy Living Themes](https://github.com/prostratepossum/omarchy-living-themes), shared with Moonlit Hearth. Switching between the two themes (or to any other) swaps the scene, cursor, prompt, terminal colors, login chime and login screen.
- New: an SDDM login screen in the Starwatch look (`./install.sh --greeter`).
- The terminal rice (`extras/`) is now a theme package that switches with the theme instead of being copied over your dotfiles. `--dotfiles` is no longer needed.
- Boot splash: install it with `living-themes boot`, or from the notification after switching to this theme.
- Upgrading: the installer removes the 1.x `starwatch-*` plugins, the old `~/.bashrc` and `looknfeel.lua` blocks and login-chime unit, and restores the prompt and lazygit files that `--dotfiles` replaced. The standalone `omarchy-starwatch-*` plugin repos are superseded.

## 1.1.0

- Starwatch cursors and click effects.

## 1.0.0

- First release.
