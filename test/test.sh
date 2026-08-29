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
if grep -qE '"(aaa|bbb|ccc)"|x-secret|JBSWY3DP' "$tmp"; then echo "FAIL: secret in menu"; exit 1; fi
grep -v "^\s*//" "$tmp" | perl -0pe 's/,(\s*\})/$1/g' | jq . >/dev/null   # valid JSON once comments stripped
rm "$tmp"; echo "menu-sync ok"

# dashlane-list (via fake dcli) must not expose password/otpSecret
out=$(dashlane-list)
if grep -qE 'password|otpSecret|JBSWY3DP' <<<"$out"; then echo "FAIL: secret in list"; exit 1; fi
[[ $(jq -r '.[0].hasOtp' <<<"$out") == true ]]
echo "list strips secrets ok"

# dashlane-copy: secret reaches the clipboard, never appears in any process argv
if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
  dashlane-copy aaa password >/dev/null 2>&1 &
  sleep 0.5
  anc=""; a=$$; while [[ $a -gt 1 ]]; do anc+="$a "; a=$(awk '{print $4}' "/proc/$a/stat"); done   # skip our own shell ancestry
  leak=$(pgrep -f 'x-secret-aaa' | grep -vxF -e "${anc// /$'\n'}" || true)
  if [[ -n $leak ]]; then echo "FAIL: secret in argv of pid(s) $leak"; exit 1; fi
  wait; [[ "$(wl-paste -n)" == "x-secret-aaa" ]] || { echo "FAIL: clipboard"; exit 1; }
  echo "copy ok (secret only in clipboard, not in argv)"
fi
