#!/usr/bin/env bash
# Remove symlinks, restore hypridle lock command, drop the menu block. Leaves dcli and its vault alone.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here"
# Only remove links that still point into this checkout — never a same-named file someone else owns.
unlink_ours() { local t=$1 r; r=$(readlink -f "$t" 2>/dev/null || true)
  if [[ -L $t && ( $r == "$here" || $r == "$here"/* ) ]]; then rm -f "$t"; elif [[ -e $t || -L $t ]]; then echo "left $t alone (not ours)" >&2; fi; }
for f in bin/*; do unlink_ours ~/.local/bin/"$(basename "$f")"; done
unlink_ours ~/.local/share/applications/dashlane-omarchy.desktop
unlink_ours ~/.config/omarchy/plugins/tobeytg.dashlane
shell=~/.config/omarchy/shell.json
if [[ -f $shell ]]; then jq 'walk(if type=="array" then map(select(.id? != "tobeytg.dashlane")) else . end)' "$shell" > "$shell.tmp" && mv "$shell.tmp" "$shell"; fi
omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
idle=~/.config/hypr/hypridle.conf
# restore only the two directives install.sh rewrote, not every mention of the name
if [[ -f $idle ]] && grep -qE '^\s*(lock_cmd|before_sleep_cmd)\s*=.*dashlane-lock' "$idle"; then
  sed -i -E 's/^(\s*lock_cmd\s*=\s*)dashlane-lock/\1omarchy-system-lock/; s/^(\s*before_sleep_cmd\s*=.*)dashlane-lock/\1omarchy-system-lock/' "$idle"
  omarchy restart hypridle >/dev/null 2>&1 || true
fi
menu=~/.config/omarchy/extensions/omarchy-menu.jsonc
if [[ -f $menu ]]; then sed -i '/>>> dashlane-omarchy/,/<<< dashlane-omarchy/d' "$menu"; fi
echo "removed (run 'dcli logout' if you also want the local vault gone)"
