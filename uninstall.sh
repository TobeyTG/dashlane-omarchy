#!/usr/bin/env bash
# Remove symlinks, restore hypridle lock command, drop the menu block. Leaves dcli and its vault alone.
set -euo pipefail
for f in bin/*; do rm -f ~/.local/bin/"$(basename "$f")"; done
idle=~/.config/hypr/hypridle.conf
[[ -f $idle ]] && sed -i 's/dashlane-lock/omarchy-system-lock/g' "$idle" && omarchy restart hypridle >/dev/null 2>&1 || true
menu=~/.config/omarchy/extensions/omarchy-menu.jsonc
[[ -f $menu ]] && sed -i '/>>> dashlane-omarchy/,/<<< dashlane-omarchy/d' "$menu"
echo "removed (run 'dcli logout' if you also want the local vault gone)"
