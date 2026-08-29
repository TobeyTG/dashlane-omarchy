#!/usr/bin/env bash
# Symlink the scripts into ~/.local/bin and generate the Omarchy menu. Nothing else is touched.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
mkdir -p ~/.local/bin
for f in "$here"/bin/*; do ln -sf "$f" ~/.local/bin/; done
if ! command -v dcli >/dev/null; then
  echo "installing dcli (official Dashlane CLI) to ~/.local/bin"
  gh release download -R Dashlane/dashlane-cli -p dcli-linux-x64 -O ~/.local/bin/dcli --clobber && chmod +x ~/.local/bin/dcli
fi
if dcli p -o json >/dev/null 2>&1; then
  dashlane-menu-sync
else
  echo "vault not unlocked — run: dcli sync    then: dashlane-menu-sync"
fi
cat <<'HINT'

Optional, add to ~/.config/hypr/bindings.lua:
  o.bind("SUPER + SHIFT + P", "Passwords", "dashlane-app")
  o.bind("SUPER + ALT + P",   "Passwords menu", "omarchy-menu summon passwords")
and to ~/.config/hypr/windows.lua (float the app):
  hl.windowrule({ float = true, size = "720 520", center = true, match = { title = "^Dashlane$" } })
HINT
