#!/usr/bin/env bash
# Remove symlinks, restore hypridle lock command, drop the menu block. Leaves dcli and its vault alone.
set -euo pipefail
cd "$(dirname "$0")"
for f in bin/*; do rm -f ~/.local/bin/"$(basename "$f")"; done
rm -f ~/.local/share/applications/dashlane-omarchy.desktop ~/.config/omarchy/plugins/dashlane-omarchy
shell=~/.config/omarchy/shell.json
[[ -f $shell ]] && jq 'walk(if type=="array" then map(select(.id? != "dashlane-omarchy.vault")) else . end)' "$shell" > "$shell.tmp" && mv "$shell.tmp" "$shell"
omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
idle=~/.config/hypr/hypridle.conf
[[ -f $idle ]] && sed -i 's/dashlane-lock/omarchy-system-lock/g' "$idle" && omarchy restart hypridle >/dev/null 2>&1 || true
menu=~/.config/omarchy/extensions/omarchy-menu.jsonc
[[ -f $menu ]] && sed -i '/>>> dashlane-omarchy/,/<<< dashlane-omarchy/d' "$menu"
echo "removed (run 'dcli logout' if you also want the local vault gone)"
