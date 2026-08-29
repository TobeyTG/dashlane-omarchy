#!/usr/bin/env bash
# Symlink the scripts into ~/.local/bin and generate the Omarchy menu. Nothing else is touched.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
DCLI_VERSION=6.2633.2
DCLI_SHA256=55d9eae31e983081441e7b27ee287fda93989a7bff617bbab9a70aa61b326acc
mkdir -p ~/.local/bin
for f in "$here"/bin/*; do ln -sf "$f" ~/.local/bin/; done
# Official dcli, pinned to a release + sha256 (see DCLI_VERSION / DCLI_SHA256 at the top of this file).
if ! command -v dcli >/dev/null || [[ "$(dcli --version)" != "$DCLI_VERSION" ]]; then
  echo "installing dcli $DCLI_VERSION (official Dashlane CLI) to ~/.local/bin"
  gh release download -R Dashlane/dashlane-cli "v$DCLI_VERSION" -p dcli-linux-x64 -O ~/.local/bin/dcli.new --clobber
  echo "$DCLI_SHA256  $HOME/.local/bin/dcli.new" | sha256sum -c - || { rm -f ~/.local/bin/dcli.new; echo "checksum mismatch — aborting"; exit 1; }
  chmod +x ~/.local/bin/dcli.new && mv ~/.local/bin/dcli.new ~/.local/bin/dcli
fi
# Don't persist the master password: after `dashlane-lock` / reboot the vault needs a real unlock.
timeout 5 dcli configure save-master-password false </dev/null >/dev/null 2>&1 || true
if dcli p -o json </dev/null >/dev/null 2>&1; then
  dashlane-menu-sync
else
  echo "vault not unlocked — run: dcli sync    then: dashlane-menu-sync"
fi
cat <<'HINT'

Optional, add to ~/.config/hypr/bindings.lua:
  o.bind("SUPER + SHIFT + P", "Passwords", "dashlane-app")
  o.bind("SUPER + ALT + P",   "Passwords menu", "omarchy-menu summon passwords")
Recommended (locks the vault whenever the screen locks or the laptop sleeps), in ~/.config/hypr/hypridle.conf:
  lock_cmd = dashlane-lock
  before_sleep_cmd = OMARCHY_LOCK_ONLY=true dashlane-lock
and to ~/.config/hypr/windows.lua (float the app):
  hl.windowrule({ float = true, size = "720 520", center = true, match = { title = "^Dashlane$" } })
HINT
