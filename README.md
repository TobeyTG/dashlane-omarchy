# dashlane-omarchy

Dashlane on Omarchy/Linux without a browser: an Omarchy menu plugin and a small native Qt (Quickshell) app, both thin wrappers around the official [`dcli`](https://github.com/Dashlane/dashlane-cli).

Secrets never touch disk or the UI — everything is "copy to clipboard" via `dcli`.

```
bin/dashlane-copy        <id> [password|login|email|otp]  copy one field, notify
bin/dashlane-menu-sync   [vault.json]  regenerate the "Passwords" submenu in omarchy-menu.jsonc (titles only)
bin/dashlane-sync        dcli sync in a floating terminal, then menu-sync
bin/dashlane-app         launch the Qt app
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

## App keys
`⏎` copy password · `^L` login · `^O` OTP · `^R` reload · `Esc` quit · double-click / icons work too.

## Notes
- Omarchy menu `provider`s are hardcoded, so the menu is generated statically; re-run `dashlane-menu-sync` (or "Sync vault" in the menu) after adding entries.
- If the vault is locked, `dcli` prompts interactively — run `dcli sync` in a terminal, then `^R`.
- Test: `test/test.sh`. Preview app with fixture: `DASHLANE_JSON=$PWD/test/vault.json dashlane-app`.
