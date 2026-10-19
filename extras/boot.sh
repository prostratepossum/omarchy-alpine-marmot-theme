#!/bin/bash
# Animated Starwatch boot splash (asks for sudo, rebuilds the initramfs).
# Run by `living-themes boot`; lives in the installed theme's extras/ folder.
exec "$(cd "$(dirname "$0")/.." && pwd)/plymouth-starwatch/install.sh" "$@"
