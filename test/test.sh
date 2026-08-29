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
# Parse exactly like Omarchy does (MenuModel.js stripJsonc: drop // lines, drop trailing commas)
perl -0pe 's/^\s*\/\/[^\n]*(\n|$)//gm; s/,(\s*[}\]])/$1/g' "$tmp" | jq . >/dev/null
# ...both when user entries follow the block (above) and on a fresh file where "}" follows it directly
fresh=$(mktemp); printf '{\n}\n' > "$fresh"; DASHLANE_MENU_FILE=$fresh dashlane-menu-sync test/vault.json >/dev/null
perl -0pe 's/^\s*\/\/[^\n]*(\n|$)//gm; s/,(\s*[}\]])/$1/g' "$fresh" | jq . >/dev/null || { echo "FAIL: fresh menu does not parse like Omarchy"; exit 1; }; rm "$fresh"
rm "$tmp"; echo "menu-sync ok"

# malformed ids never reach a shell action string
bad=$(mktemp); jq '. + [{"id":"x; rm -rf ~","title":"Evil","url":"https://evil.example","password":"p"}]' test/vault.json > "$bad"
tmp2=$(mktemp); printf '{\n}\n' > "$tmp2"
DASHLANE_MENU_FILE=$tmp2 dashlane-menu-sync "$bad" 2>"$tmp2.err" >/dev/null
grep -q "unexpected ids" "$tmp2.err" || { echo "FAIL: malformed id not reported"; exit 1; }
grep -q "rm -rf" "$tmp2" && { echo "FAIL: malformed id reached the menu"; exit 1; }
[[ $(grep -c '"passwords\.[0-9]*":' "$tmp2") == 3 ]] || { echo "FAIL: good entries dropped with the bad one"; exit 1; }
rm -f "$bad" "$tmp2" "$tmp2.err"; echo "malformed ids filtered ok"

# locked vault: every entry point must fail cleanly, never hang, never fall through
DCLI_LOCKED=1 timeout 5 dashlane-list >/dev/null 2>&1 && { echo "FAIL: list succeeded while locked"; exit 1; }
DCLI_LOCKED=1 timeout 5 dashlane-field aaa password >/dev/null 2>&1 && { echo "FAIL: field succeeded while locked"; exit 1; }
DCLI_LOCKED=1 timeout 5 dashlane-menu-sync >/dev/null 2>&1 && { echo "FAIL: menu-sync succeeded while locked"; exit 1; }
echo "locked-vault paths fail cleanly"

# dashlane-list (via fake dcli) must not expose password/otpSecret
out=$(dashlane-list)
if grep -qE 'password|otpSecret|JBSWY3DP' <<<"$out"; then echo "FAIL: secret in list"; exit 1; fi
[[ $(jq -r '.[0].hasOtp' <<<"$out") == true ]]
echo "list strips secrets ok"

# dashlane-copy: secret reaches the clipboard, never appears in any process argv
if [[ -z ${WAYLAND_DISPLAY:-} && -n ${CI:-} ]]; then echo "FAIL: CI has no Wayland display — clipboard/argv tests would be skipped"; exit 1; fi
[[ -n ${WAYLAND_DISPLAY:-} ]] || echo "SKIPPED clipboard/argv tests (no WAYLAND_DISPLAY)"
if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
  # locked: copy must give up within the deadline, with a clear message, and leave the clipboard alone
  wl-copy --clear; start=$SECONDS
  PATH="$PWD/test/fake/nolauncher:$PATH" DCLI_LOCKED=1 timeout 60 dashlane-copy --quiet aaa password >/dev/null 2>&1 && { echo "FAIL: locked copy succeeded"; exit 1; }
  (( SECONDS - start < 30 )) || { echo "FAIL: locked copy took too long"; exit 1; }
  [[ -z "$(wl-paste -n 2>/dev/null || true)" ]] || { echo "FAIL: locked copy touched the clipboard"; exit 1; }
  echo "locked copy fails fast, clipboard untouched"
  # login window opened but never completes: give up at DASHLANE_LOGIN_TIMEOUT, not later
  start=$SECONDS
  PATH="$PWD/test/fake/hanginglogin:$PATH" DASHLANE_LOGIN_TIMEOUT=2 DCLI_LOCKED=1 timeout 60 dashlane-copy --quiet aaa password >/dev/null 2>&1 && { echo "FAIL: hanging login copy succeeded"; exit 1; }
  (( SECONDS - start < 20 )) || { echo "FAIL: hanging login not bounded ($((SECONDS-start))s)"; exit 1; }
  pgrep -x dcli -a 2>/dev/null | awk '/ sync$/{print $1}' | xargs -r kill 2>/dev/null || true   # stop the fake login
  echo "hanging login bounded by DASHLANE_LOGIN_TIMEOUT"
  dashlane-copy aaa password >/dev/null 2>&1 &
  sleep 0.5
  anc=""; a=$$; while [[ $a -gt 1 ]]; do anc+="$a "; a=$(awk '{print $4}' "/proc/$a/stat"); done   # skip our own shell ancestry
  leak=$(pgrep -f 'x-secret-aaa' | grep -vxF -e "${anc// /$'\n'}" || true)
  if [[ -n $leak ]]; then echo "FAIL: secret in argv of pid(s) $leak"; exit 1; fi
  wait; clip_is() { for _ in $(seq 1 20); do [[ "$(wl-paste -n 2>/dev/null)" == "$1" ]] && return; sleep 0.1; done; return 1; }   # wl-copy forks; give its server a moment
  clip_is x-secret-aaa || { echo "FAIL: clipboard"; exit 1; }
  echo "copy ok (secret only in clipboard, not in argv)"
  printf 'x-secret-stdin' | dashlane-copy --quiet --stdin password >/dev/null 2>&1
  clip_is x-secret-stdin || { echo "FAIL: stdin copy"; exit 1; }
  echo "stdin copy ok"
fi
