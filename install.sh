#!/usr/bin/env bash
# Sets up everything the bar plugin can't do by itself: scripts on PATH, launcher entry, the
# pinned official dcli, the Omarchy menu and the vault-lock hook in hypridle. Re-runnable.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)

# Official dcli release, pinned. Update both when bumping. Linux builds exist for x86_64 only.
DCLI_VERSION=6.2633.2
DCLI_SHA256_X64=55d9eae31e983081441e7b27ee287fda93989a7bff617bbab9a70aa61b326acc

# --- preflight: report everything missing at once -------------------------------------------
missing=()
for c in curl jq wl-copy wl-paste notify-send quickshell omarchy-shell sha256sum; do command -v "$c" >/dev/null || missing+=("$c"); done
if ((${#missing[@]})); then
  echo "missing: ${missing[*]}  (Omarchy ships all of these; install them and re-run)" >&2; exit 1
fi

# --- scripts, launcher, plugin --------------------------------------------------------------
mkdir -p ~/.local/bin ~/.local/share/applications ~/.config/omarchy/plugins
for f in "$here"/bin/*; do ln -sf "$f" ~/.local/bin/; done
ln -sf "$here/dashlane-omarchy.desktop" ~/.local/share/applications/
# The repo is the plugin. Skip the symlink when already installed via `omarchy plugin add`.
[[ $here == "$HOME/.local/share/omarchy/plugins/"* || $here == "$HOME/.config/omarchy/plugins/"* ]] \
  || ln -sfn "$here" ~/.config/omarchy/plugins/tobeytg.dashlane
rm -f ~/.config/omarchy/plugins/dashlane-omarchy                               # pre-2026-08-30 install location
sed -i 's/"dashlane-omarchy.vault"/"tobeytg.dashlane"/' ~/.config/omarchy/shell.json 2>/dev/null || true   # id rename, 2026-08-30 — delete after 2027
omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
grep -q '"tobeytg.dashlane"' ~/.config/omarchy/shell.json 2>/dev/null \
  || omarchy bar put tobeytg.dashlane --section center >/dev/null 2>&1 || true

# --- dcli: install only if missing or older than the pin; never downgrade -------------------
have=$(dcli --version 2>/dev/null | sed -E 's/^v//; s/[[:space:]].*//' || true)
if [[ -z $have ]] || [[ "$(printf '%s\n%s\n' "$DCLI_VERSION" "$have" | sort -V | head -1)" != "$DCLI_VERSION" ]]; then
  case $(uname -m) in
    x86_64) asset=dcli-linux-x64; sha=$DCLI_SHA256_X64 ;;
    *) echo "dcli has no official Linux build for $(uname -m); install it yourself (e.g. npm i -g @dashlane/cli) and re-run" >&2; exit 1 ;;
  esac
  echo "installing dcli $DCLI_VERSION (official Dashlane CLI) to ~/.local/bin"
  curl -fsSL "https://github.com/Dashlane/dashlane-cli/releases/download/v$DCLI_VERSION/$asset" -o ~/.local/bin/dcli.new
  echo "$sha  $HOME/.local/bin/dcli.new" | sha256sum -c --quiet - \
    || { rm -f ~/.local/bin/dcli.new; echo "checksum mismatch — aborting" >&2; exit 1; }
  chmod +x ~/.local/bin/dcli.new && mv ~/.local/bin/dcli.new ~/.local/bin/dcli
else
  echo "dcli $have present (pin is $DCLI_VERSION), keeping it"
fi
# dcli's default keeps the master password encrypted in the OS keychain; with it off every call
# prompts interactively and the app can't work. Locking is done with `dcli lock` (dashlane-lock).

# --- menu ----------------------------------------------------------------------------------
if dcli p -o json </dev/null >/dev/null 2>&1; then
  dashlane-menu-sync
else
  echo "vault not unlocked — run: dcli sync    then: dashlane-menu-sync"
fi

# --- lock the vault with the screen ---------------------------------------------------------
idle=~/.config/hypr/hypridle.conf
if [[ -f $idle ]] && ! grep -q dashlane-lock "$idle"; then
  cp "$idle" "$idle.bak.$(date +%s)"
  sed -i -E 's/^(\s*lock_cmd\s*=\s*)omarchy-system-lock/\1dashlane-lock/; s/^(\s*before_sleep_cmd\s*=.*)omarchy-system-lock/\1dashlane-lock/' "$idle"
  if grep -q dashlane-lock "$idle"; then
    omarchy restart hypridle >/dev/null 2>&1 || true
    echo "hypridle: vault now locks with the screen (lock_cmd = dashlane-lock)"
  else
    echo "WARNING: $idle has no 'lock_cmd = omarchy-system-lock' line — set lock_cmd = dashlane-lock yourself, or the vault will not lock with the screen" >&2
  fi
fi

cat <<'HINT'

Optional, add to ~/.config/hypr/bindings.lua:
  o.bind("SUPER + SHIFT + P", "Passwords", "dashlane-app")
  o.bind("SUPER + ALT + P",   "Passwords menu", "omarchy-menu summon passwords")
and to ~/.config/hypr/windows.lua (float the app):
  hl.windowrule({ float = true, size = "960 600", center = true, match = { title = "^Dashlane$" } })
HINT
