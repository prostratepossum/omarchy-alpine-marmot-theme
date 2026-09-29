#!/bin/bash
# Install the Starwatch plymouth theme and rebuild the initramfs.
#   ./install.sh            install + activate
#   ./install.sh --revert   switch back to the stock Omarchy splash
# Run as your user; it asks for sudo itself.
set -euo pipefail
cd "$(dirname "$0")"

rebuild() {
  if command -v limine-mkinitcpio >/dev/null; then
    sudo limine-mkinitcpio
  else
    sudo mkinitcpio -P
  fi
}

if [[ ${1:-} == "--revert" ]]; then
  sudo plymouth-set-default-theme omarchy
  rebuild
  echo "Stock Omarchy boot splash restored."
  exit 0
fi

files=(starwatch.plymouth starwatch.script background.png badge.png halo.png star.png
       firefly.png bullet.png streak.png entry.png progress_box.png progress_bar.png)
for f in "${files[@]}"; do [[ -f $f ]] || { echo "missing $f (run build-assets.sh)" >&2; exit 1; }; done

sudo install -d -m 755 /usr/share/plymouth/themes/starwatch
sudo install -m 644 "${files[@]}" /usr/share/plymouth/themes/starwatch/
sudo plymouth-set-default-theme starwatch
rebuild
echo "Starwatch boot splash installed. Revert any time with: $0 --revert"
