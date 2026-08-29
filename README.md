# dashlane-omarchy

Dashlane on Omarchy/Linux without a browser: an Omarchy menu plugin and a small native Qt (Quickshell) app, both thin wrappers around the official [`dcli`](https://github.com/Dashlane/dashlane-cli).

Secrets never touch disk or the UI — everything is "copy to clipboard" via `dcli`.

```
bin/dashlane-copy        <id> [password|login|email|otp]  copy one field, notify
bin/dashlane-menu-sync   [vault.json]  regenerate the "Passwords" submenu in omarchy-menu.jsonc (titles only)
bin/dashlane-sync        dcli sync in a floating terminal, then menu-sync
bin/dashlane-app         launch the Qt app
bin/dashlane-list        vault metadata as JSON (no secrets)
bin/dashlane-field       <id> <field>  print one field on demand
bin/dashlane-lock        dcli lock + close app + omarchy-system-lock (for hypridle)
app/dashlane.qml         the app (Quickshell, themed from the current Omarchy theme)
test/test.sh             self-check for menu generation
```

## Install
```sh
./install.sh        # symlinks into ~/.local/bin, installs dcli if missing
dcli sync           # first login (interactive), then:
dashlane-menu-sync
```
Then `omarchy menu summon passwords` or `dashlane-app`. See install.sh output for keybind/float-rule snippets.

## Details sidebar
Click a row or press `→` to open the entry like the extension's detail pane: website (open), login/email/secondary login (copy), password (masked, eye to reveal for 10s), live one-time code with countdown, note (fetched on demand), category, modified/last used/use count, strength. Password history is not exposed by the Dashlane CLI, so it can't be shown.

## App keys
`⏎` copy password · `^L` login (falls back to email) · `^O` OTP · `^S` reveal password (10s) · `^U` open site · `^R` reload · `Esc` quit · row icons do the same. Clipboard clears itself after 30s.

## Notes
- Omarchy menu `provider`s are hardcoded, so the menu is generated statically; re-run `dashlane-menu-sync` (or "Sync vault" in the menu) after adding entries.
- If the vault is locked, `dcli` prompts interactively — run `dcli sync` in a terminal, then `^R`.
- Test: `test/test.sh`. Preview app with fixture: `DASHLANE_JSON=$PWD/test/vault.json dashlane-app`.

## Security model
- All auth/crypto is the official `dcli` (pinned release + sha256 in `install.sh`). The app never sees your master password — login happens in dcli's own terminal prompt.
- `dashlane-list` strips `password`/`otpSecret` before anything reaches the app or menu; secrets are fetched per field on demand and travel only through pipes (never argv, never disk).
- Clipboard: `wl-copy --sensitive` (kept out of Omarchy clipboard history), auto-cleared after 30s. Reveal hides after 10s and is wiped on quit.
- `install.sh` sets `dcli configure save-master-password false`; `dashlane-lock` runs `dcli lock` + closes the app before the screen locks — set it as hypridle `lock_cmd`/`before_sleep_cmd` so the vault re-asks the master password after every lock/sleep.
- Not covered (browser-extension territory): autofill and domain-matching. Keep the extension for in-browser logins.
