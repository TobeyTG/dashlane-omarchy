#!/usr/bin/env bash
# Self-check: menu generation from a fixture, idempotent re-run, no secrets leaked.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp); printf '{\n  "personal": {"icon":"","label":"Personal"}\n}\n' > "$tmp"
DASHLANE_MENU_FILE=$tmp bin/dashlane-menu-sync test/vault.json >/dev/null
DASHLANE_MENU_FILE=$tmp bin/dashlane-menu-sync test/vault.json >/dev/null   # idempotent
[[ $(grep -c '>>> dashlane' "$tmp") == 1 ]]
grep -q '"personal"' "$tmp"                                   # existing entries preserved
[[ $(grep -c '"passwords\.[0-9]*":' "$tmp") == 3 ]]
[[ $(grep -c 'Copy OTP' "$tmp") == 1 ]]                       # only GitHub has otp
! grep -qE '"(x|y|z)"|JBSWY3DP' "$tmp"                        # no secrets in menu
grep -v "^\s*//" "$tmp" | perl -0pe 's/,(\s*\})/$1/g' | jq . >/dev/null   # valid JSON once comments stripped
echo "menu-sync ok"; rm "$tmp"
