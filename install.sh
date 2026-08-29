#!/usr/bin/env bash
# Symlink the scripts into ~/.local/bin and generate the Omarchy menu. Nothing else is touched.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
DCLI_VERSION=6.2633.2
DCLI_SHA256=55d9eae31e983081441e7b27ee287fda93989a7bff617bbab9a70aa61b326acc
mkdir -p ~/.local/bin
for f in "$here"/bin/*; do ln -sf "$f" ~/.local/bin/; done
mkdir -p ~/.local/share/applications && ln -sf "$here/dashlane-omarchy.desktop" ~/.local/share/applications/
# Official dcli, pinned to a release + sha256 (see DCLI_VERSION / DCLI_SHA256 at the top of this file).
if ! command -v dcli >/dev/null || [[ "$(dcli --version)" != "$DCLI_VERSION" ]]; then
  echo "installing dcli $DCLI_VERSION (official Dashlane CLI) to ~/.local/bin"
  gh release download -R Dashlane/dashlane-cli "v$DCLI_VERSION" -p dcli-linux-x64 -O ~/.local/bin/dcli.new --clobber
  echo "$DCLI_SHA256  $HOME/.local/bin/dcli.new" | sha256sum -c - || { rm -f ~/.local/bin/dcli.new; echo "checksum mismatch — aborting"; exit 1; }
  chmod +x ~/.local/bin/dcli.new && mv ~/.local/bin/dcli.new ~/.local/bin/dcli
fi
# Keep dcli's default (master password encrypted in the OS keychain) — with it off, every dcli call
# prompts interactively and the app can't work. Locking is done with `dcli lock` (see dashlane-lock).
if dcli p -o json </dev/null >/dev/null 2>&1; then
  dashlane-menu-sync
else
  echo "vault not unlocked — run: dcli sync    then: dashlane-menu-sync"
fi
# Lock the vault together with the screen: point hypridle's lock_cmd/before_sleep_cmd at dashlane-lock
# (which then execs omarchy-system-lock). Idempotent; a timestamped backup is kept.
idle=~/.config/hypr/hypridle.conf
if [[ -f $idle ]] && ! grep -q dashlane-lock "$idle"; then
  cp "$idle" "$idle.bak.$(date +%s)"
  sed -i -E 's/^(\s*lock_cmd\s*=\s*)omarchy-system-lock/\1dashlane-lock/; s/^(\s*before_sleep_cmd\s*=.*)omarchy-system-lock/\1dashlane-lock/' "$idle"
  omarchy restart hypridle >/dev/null 2>&1 || true
  echo "hypridle: vault now locks with the screen (lock_cmd = dashlane-lock)"
fi

cat <<'HINT'

Optional, add to ~/.config/hypr/bindings.lua:
  o.bind("SUPER + SHIFT + P", "Passwords", "dashlane-app")
  o.bind("SUPER + ALT + P",   "Passwords menu", "omarchy-menu summon passwords")
and to ~/.config/hypr/windows.lua (float the app):
  hl.windowrule({ float = true, size = "720 520", center = true, match = { title = "^Dashlane$" } })
HINT
