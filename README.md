<div align="center" width="150px">
  <img style="width: 150px; height: auto;" src="https://raw.githubusercontent.com/TobeyTG/dashlane-omarchy/master/assets/logo.svg" alt="Logo - Dashlane for Omarchy" />
</div>
<div align="center">
  <h1>Dashlane for Omarchy</h1>
  <p>Your Dashlane vault in the Omarchy bar, menu and a native app — on the official CLI</p>
  <a href="https://github.com/TobeyTG/dashlane-omarchy/releases">
    <img alt="GitHub release" src="https://img.shields.io/github/v/release/tobeytg/dashlane-omarchy?include_prereleases&label=release&logo=github">
  </a>
  <a href="https://github.com/TobeyTG/dashlane-omarchy/actions/workflows/ci.yml">
    <img alt="CI" src="https://github.com/TobeyTG/dashlane-omarchy/actions/workflows/ci.yml/badge.svg">
  </a>
  <a href="LICENSE">
    <img alt="License" src="https://img.shields.io/github/license/tobeytg/dashlane-omarchy">
  </a>
</div>

---

A plugin for [Omarchy](https://omarchy.org) that brings [Dashlane](https://www.dashlane.com/) to Linux outside the browser: a 🔒 in the bar with a quick-copy popup, a native vault app with a details sidebar, and a "Passwords" submenu in the Omarchy menu.

Everything runs on the official [`dcli`](https://github.com/Dashlane/dashlane-cli). No reverse engineering, no custom crypto, and your master password never touches this code.

![screenshot](docs/screenshot.png)

## Requirements
Omarchy ships all of them: Quickshell (`omarchy-shell`), `jq`, `wl-clipboard`, `libnotify`, `curl`. `install.sh` checks and lists anything missing. `dcli` is downloaded pinned and sha256-checked (x86_64 only — upstream publishes no Linux ARM build).

## Installation

```bash
omarchy plugin add https://github.com/TobeyTG/dashlane-omarchy --enable
```

Click the 🔒 in the bar → **Finish setup** → **Open app** → **Log in with dcli**. That's it.

☝️ *Finish setup* runs `install.sh`: it downloads the pinned `dcli` release (sha256-checked), wires the vault lock into hypridle, generates the menu and adds the launcher entry. You can also run it yourself after `git clone`.

☝️ Login happens in a terminal running the official `dcli sync` — email, master password, device code. This plugin only ever calls `dcli`, it never sees those.

## Usage

**Bar popup** — click the 🔒 (or bind `omarchy-shell shell toggle tobeytg.dashlane`): type, `⏎` copies the password, `^L` login, `^O` one-time code, `^⏎` opens the app.

**App** — `dashlane-app`, the "Dashlane" launcher entry, or middle-click the 🔒:

| Key | Action |
|---|---|
| `⏎` | copy password |
| `^L` / `^E` / `^O` | copy login / email / one-time code |
| `→` `Tab` / `←` `Esc` | open / close details |
| `^S` / `^N` | reveal password (10 s) / show note |
| `^U` | open website |
| `^R` | reload · `PgUp` `PgDn` `^Home` `^End` jump |

**Menu** — `omarchy menu summon passwords` → entry → copy password / login / OTP.

☝️ New vault entries show up in the app on `^R` and in the menu after *Passwords → Sync vault* (`dashlane-menu-sync`).

Handy keybinds for `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + SHIFT + P", "Passwords", "dashlane-app")
o.bind("SUPER + ALT + P",   "Passwords menu", "omarchy-menu summon passwords")
```

## Security

- **Auth and crypto are `dcli`'s.** Pinned release, sha256-verified. Unlock is dcli's own prompt.
- **Secrets never enter the UI wholesale.** `dashlane-list` strips `password`/`otpSecret`. Opening an entry in the sidebar fetches *that entry's* password (so reveal/copy are instant) and its OTP; the note only on request. Fields travel through pipes only (never argv, never disk) and are cleared on entry change, close, quit or lock. The bar popup and the menu never prefetch anything.
- **"Cleared" means at the application level.** QML/JS strings can't be scrubbed from memory; the same is true inside `dcli` (Node). Memory forensics on a live session are out of scope — see SECURITY.md.
- **Clipboard.** `wl-copy --sensitive` (Omarchy's clipboard history skips it), cleared after 30 s.
- **Lock.** `dashlane-lock` runs `dcli lock` before the screen locks or the laptop sleeps.
- **Not covered:** autofill and domain matching — keep the browser extension for in-browser logins. Password history isn't exported by `dcli`.

☝️ Like every desktop password manager, the vault is readable by anything running as your user while it's unlocked. Lock it (it does so with the screen) and don't run untrusted code.

## Development

```bash
test/test.sh                                                        # self-tests with a fake dcli
DASHLANE_JSON=$PWD/test/vault.json PATH=$PWD/test/fake:$PATH dashlane-app   # app with fixture data, no login
omarchy plugin validate .
```

```
manifest.json, BarWidget.qml, Panel.qml   the Omarchy plugin (bar icon + popup)
app/                                      the Quickshell app (Vault.qml holds all dcli-facing logic)
bin/                                      dashlane-list / -field / -copy / -lock / -menu-sync / -sync / -app
install.sh · uninstall.sh                 the non-plugin bits
```

`./uninstall.sh` reverts everything except `dcli` and its vault.

## 📝 License

[MIT License](LICENSE)

Not affiliated with Dashlane. Made by [TobeyTG](https://tobeytg.de/) ✌️
