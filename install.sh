#!/bin/bash
# Alpine Marmot / Starwatch for Omarchy.
#
#   ./install.sh                 theme + cursors + Living Themes (live wallpaper, lock screen,
#                                intro, click effects, theme switcher)
#   ./install.sh --all           ...plus the login chime and the SDDM login screen (sudo)
#   ./install.sh --sound         also play the theme's chime at login
#   ./install.sh --greeter       also install the SDDM login screen (asks for sudo)
#   ./install.sh --yes           remove the old 1.x plugins without asking
#   ./install.sh --no-plugins    theme, cursors and theme switcher only (no shell plugins)
#   ./install.sh --no-cursors    keep your current mouse cursor
#   ./install.sh --uninstall     remove this theme (switch to another theme first)
#
# --dotfiles is gone: the prompt, fastfetch, lazygit and eza/fzf colors now
# switch with the theme (see extras/). It's still accepted and does nothing.
#
# Boot splash (needs sudo, rebuilds the initramfs): run `living-themes boot`,
# or use the notification Omarchy shows after switching to this theme.
set -euo pipefail

THEME=alpine-marmot
TITLE="Alpine Marmot"
MARK="✦"
CURSOR=Starwatch
WALLPAPER=0-starwatch.jpg
SPLASH=plymouth-starwatch
THEME_FILES=(colors.toml btop.theme icons.theme preview.png backgrounds plymouth plymouth-starwatch extras)
OLD_BLOCK=starwatch                 # 1.x marker blocks in ~/.bashrc and looknfeel.lua
OLD_UNIT=starwatch-login-sound.service
OLD_LOGO=marmot-starwatch.txt       # 1.x fastfetch logo copied into ~/.config/fastfetch

# Shared plugins and theme switcher: https://github.com/prostratepossum/omarchy-living-themes
LIVING_URL=https://github.com/prostratepossum/omarchy-living-themes.git
LIVING_REF=v1.0.0

SRC="$(cd "$(dirname "$0")" && pwd)"
THEME_DIR="$HOME/.config/omarchy/themes/$THEME"
CURSOR_DIR="$HOME/.local/share/icons/$CURSOR"
LIVING_DIR="$HOME/.local/share/omarchy-living-themes"
LOOKNFEEL="$HOME/.config/hypr/looknfeel.lua"

cursors=1 uninstall=0 living_args=()
for arg in "$@"; do
  case "$arg" in
  --all) living_args+=(--sound --greeter) ;;
  --sound | --greeter | --yes | --no-plugins) living_args+=("$arg") ;;
  -y) living_args+=(--yes) ;;
  --dotfiles) echo "note: --dotfiles is no longer needed; the terminal rice switches with the theme" ;;
  --no-cursors) cursors=0 ;;
  --uninstall) uninstall=1 ;;
  -h | --help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

command -v omarchy >/dev/null || { echo "This needs Omarchy (https://omarchy.org)." >&2; exit 1; }

# Where the shared part lives: a checkout next to this repo (development), or
# a pinned clone in ~/.local/share.
living_src() {
  if [[ -x $SRC/../omarchy-living-themes/install.sh ]]; then
    (cd "$SRC/../omarchy-living-themes" && pwd)
  else
    echo "$LIVING_DIR"
  fi
}

if (( uninstall )); then
  if [[ $(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null) == "$THEME" ]]; then
    echo "$TITLE is the active theme. Switch first (omarchy theme set <name>), then run --uninstall again." >&2
    exit 1
  fi
  [[ $SRC -ef $THEME_DIR ]] || rm -rf "$THEME_DIR"
  rm -rf "$CURSOR_DIR"
  echo "Removed the $TITLE theme and its cursors."
  if [[ $SRC -ef $THEME_DIR ]]; then
    echo "This clone is the installed theme folder; delete it yourself: rm -rf $THEME_DIR"
  fi
  echo "Living Themes (the shared plugins and theme switcher) is still installed, since"
  if [[ $(living_src) == "$LIVING_DIR" ]]; then
    echo "other themes can use it. To remove it too: $LIVING_DIR/install.sh --uninstall && rm -rf $LIVING_DIR"
  else
    echo "other themes can use it. To remove it too: $(living_src)/install.sh --uninstall"
  fi
  exit 0
fi

# 1.x put the rice in place with --dotfiles and its own marker blocks. Take
# those back out so the theme switcher starts clean, and put the files they
# replaced back where they were.
restore_old() {
  local target=$1 ours=$2 bak
  [[ -f $target && ! -L $target ]] || return 0
  cmp -s "$target" "$ours" || return 0
  bak=$(ls -t "$target".bak.* 2>/dev/null | head -1 || true)
  if [[ -n $bak ]]; then
    mv "$bak" "$target"
    echo "  restored your $target from $(basename "$bak")"
  else
    rm -f "$target"
  fi
}

migrate_1x() {
  local found=0
  if grep -q "# >>> $OLD_BLOCK >>>" "$HOME/.bashrc" 2>/dev/null; then
    sed -i "/# >>> $OLD_BLOCK >>>/,/# <<< $OLD_BLOCK <<</d" "$HOME/.bashrc"; found=1
  fi
  if grep -q -- "-- >>> $OLD_BLOCK cursor >>>" "$LOOKNFEEL" 2>/dev/null; then
    sed -i "/-- >>> $OLD_BLOCK cursor >>>/,/-- <<< $OLD_BLOCK cursor <<</d" "$LOOKNFEEL"; found=1
  fi
  if [[ -f $HOME/.config/systemd/user/$OLD_UNIT ]]; then
    systemctl --user disable "$OLD_UNIT" >/dev/null 2>&1 || true
    rm -f "$HOME/.config/systemd/user/$OLD_UNIT"; found=1
  fi
  restore_old "$HOME/.config/starship.toml" "$SRC/extras/starship.toml"
  restore_old "$HOME/.config/lazygit/config.yml" "$SRC/extras/lazygit.yml"
  if grep -q "$OLD_LOGO" "$HOME/.config/fastfetch/config.jsonc" 2>/dev/null && [[ ! -L $HOME/.config/fastfetch/config.jsonc ]]; then
    local bak
    bak=$(ls -t "$HOME/.config/fastfetch/config.jsonc".bak.* 2>/dev/null | head -1 || true)
    if [[ -n $bak ]]; then mv "$bak" "$HOME/.config/fastfetch/config.jsonc"; else rm -f "$HOME/.config/fastfetch/config.jsonc"; fi
    found=1
  fi
  rm -f "$HOME/.config/fastfetch/$OLD_LOGO"
  if (( found )); then echo "  cleaned up the 1.x shell colors, cursor line and login chime"; fi
  return 0
}

echo "$MARK Installing the $TITLE theme"
migrate_1x
mkdir -p "$THEME_DIR"
# Skip the copy when run from a clone made by `omarchy theme install`.
if ! [[ $SRC -ef $THEME_DIR ]]; then
  for f in "${THEME_FILES[@]}"; do rm -rf "${THEME_DIR:?}/$f"; cp -a "$SRC/$f" "$THEME_DIR/"; done
fi

if (( cursors )); then
  echo "$MARK Installing the $CURSOR cursors"
  rm -rf "$CURSOR_DIR"
  mkdir -p "$(dirname "$CURSOR_DIR")"
  cp -a "$SRC/cursors/$CURSOR" "$CURSOR_DIR"
fi

echo "$MARK Getting Living Themes ($LIVING_REF)"
LIVING=$(living_src)
if [[ $LIVING == "$LIVING_DIR" ]]; then
  if [[ -d $LIVING_DIR/.git ]]; then
    git -C "$LIVING_DIR" fetch -q --depth 1 origin tag "$LIVING_REF"
    git -C "$LIVING_DIR" checkout -q "$LIVING_REF"
  else
    rm -rf "$LIVING_DIR"
    git clone -q --depth 1 --branch "$LIVING_REF" "$LIVING_URL" "$LIVING_DIR"
  fi
else
  echo "  using the checkout at $LIVING"
fi
"$LIVING/install.sh" "${living_args[@]}"

echo "$MARK Switching to $TITLE"
omarchy theme set "$THEME"
# theme set may pick a random wallpaper; the animated one is the default.
omarchy theme bg set "$THEME_DIR/backgrounds/$WALLPAPER" >/dev/null 2>&1 || true
"$HOME/.local/bin/living-themes" greeter >/dev/null 2>&1 || true

cat <<DONE

$MARK Done. Switching to another theme and back swaps the scene, cursor, prompt and login screen.
  living-themes boot      animated boot splash (sudo; $THEME_DIR/$SPLASH/install.sh --revert undoes it)
DONE
