#!/usr/bin/env bash
# Self-check: menu generation from a fixture, idempotent re-run, no secrets leaked,
# metadata filter strips secrets, copy never puts the secret in argv.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$PWD/bin:$PWD/test/fake:$PATH"
tmp=$(mktemp); printf '{\n  "personal": {"icon":"","label":"Personal"}\n}\n' > "$tmp"
DASHLANE_MENU_FILE=$tmp dashlane-menu-sync test/vault.json >/dev/null
DASHLANE_MENU_FILE=$tmp dashlane-menu-sync test/vault.json >/dev/null   # idempotent
[[ $(grep -c '>>> dashlane' "$tmp") == 1 ]]
grep -q '"personal"' "$tmp"                                   # existing entries preserved
[[ $(grep -c '"passwords\.[0-9]*":' "$tmp") == 3 ]]
[[ $(grep -c 'Copy OTP' "$tmp") == 1 ]]                       # only GitHub has otp
! grep -qE '"(aaa|bbb|ccc)"|x-secret|JBSWY3DP' "$tmp"                        # no secrets in menu
grep -v "^\s*//" "$tmp" | perl -0pe 's/,(\s*\})/$1/g' | jq . >/dev/null   # valid JSON once comments stripped
rm "$tmp"; echo "menu-sync ok"

# dashlane-list (via fake dcli) must not expose password/otpSecret
out=$(dashlane-list)
! grep -qE 'password|otpSecret|JBSWY3DP' <<<"$out"
[[ $(jq -r '.[0].hasOtp' <<<"$out") == true ]]
echo "list strips secrets ok"

# dashlane-copy: secret reaches the clipboard, never appears in any process argv
if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
  dashlane-copy aaa password >/dev/null 2>&1 &
  sleep 0.5; ! ps -eo args | grep -v grep | grep -q 'x-secret-aaa'
  wait; [[ "$(wl-paste -n)" == "x-secret-aaa" ]]
  echo "copy ok (secret only in clipboard, not in argv)"
fi
