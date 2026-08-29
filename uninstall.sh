#!/usr/bin/env bash
# Remove symlinks, restore hypridle lock command, drop the menu block. Leaves dcli and its vault alone.
set -euo pipefail
cd "$(dirname "$0")"
for f in bin/*; do rm -f ~/.local/bin/"$(basename "$f")"; done
rm -f ~/.local/share/applications/dashlane-omarchy.desktop ~/.config/omarchy/plugins/tobeytg.dashlane
shell=~/.config/omarchy/shell.json
if [[ -f $shell ]]; then jq 'walk(if type=="array" then map(select(.id? != "tobeytg.dashlane")) else . end)' "$shell" > "$shell.tmp" && mv "$shell.tmp" "$shell"; fi
omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
idle=~/.config/hypr/hypridle.conf
if [[ -f $idle ]]; then sed -i 's/dashlane-lock/omarchy-system-lock/g' "$idle"; omarchy restart hypridle >/dev/null 2>&1 || true; fi
menu=~/.config/omarchy/extensions/omarchy-menu.jsonc
if [[ -f $menu ]]; then sed -i '/>>> dashlane-omarchy/,/<<< dashlane-omarchy/d' "$menu"; fi
echo "removed (run 'dcli logout' if you also want the local vault gone)"
