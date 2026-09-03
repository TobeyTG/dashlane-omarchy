# Changelog

## [0.1.2](https://github.com/TobeyTG/dashlane-omarchy/compare/v0.1.1...v0.1.2) (2026-09-02)


### Bug Fixes

* **security:** bound stdin copy, auto-hide notes, no /tmp marker file ([87dbe5b](https://github.com/TobeyTG/dashlane-omarchy/commit/87dbe5b6bae36db4f44c713f199456d986fcd63d))
* **security:** bound vault data, no prefetch, safe install, pin CI ([e5e44eb](https://github.com/TobeyTG/dashlane-omarchy/commit/e5e44eb39f7e245da6916bff884e71d9a297d69d))

## [0.1.1](https://github.com/TobeyTG/dashlane-omarchy/compare/v0.1.0...v0.1.1) (2026-08-29)


### Bug Fixes

* **app:** stop the locked view flickering while polling for login ([f1d4630](https://github.com/TobeyTG/dashlane-omarchy/commit/f1d46302f385b46770ed656fc92fb0bc99ab6aae))
* **bar:** make Ctrl+Enter open the app; reject copies while one runs ([54d45fd](https://github.com/TobeyTG/dashlane-omarchy/commit/54d45fdf15a72947bd0f39482ec3fe384fe0b4cb))
* **cli:** usage errors, dcli fallback on PATH, empty-title menu labels ([fdc219b](https://github.com/TobeyTG/dashlane-omarchy/commit/fdc219b8f46ca0eee2c141198f808c206b0531ae))
* **copy:** 5-min login window (overridable), warn when --sensitive is unavailable ([6e4610b](https://github.com/TobeyTG/dashlane-omarchy/commit/6e4610b594b8b9a51bbefa3a57961a0abadac0da))
* **copy:** bound the login wait and match the dcli sync process tightly ([dfdd553](https://github.com/TobeyTG/dashlane-omarchy/commit/dfdd553815805271424f0080f038bac201d14ced))
* **copy:** feature-detect wl-copy --sensitive (absent before wl-clipboard 2.2.2) ([b06b9a0](https://github.com/TobeyTG/dashlane-omarchy/commit/b06b9a02c9d91885a8005968965696bdff530860))
* **install:** curl instead of gh, arch check, never downgrade dcli, preflight ([6cdaf1f](https://github.com/TobeyTG/dashlane-omarchy/commit/6cdaf1f122d7d8910e1dc0bda02dfbe30c9a2428))
* **menu:** only allow safe entry ids in shell actions ([55c3f95](https://github.com/TobeyTG/dashlane-omarchy/commit/55c3f95136f8a0ec28baba02b7b945c20bbff573))
* **plugin:** decode and shell-quote the plugin path ([aaa0fbe](https://github.com/TobeyTG/dashlane-omarchy/commit/aaa0fbececc864f7252e2bd54fbf03a5a8a5683c))

## [0.1.0](https://github.com/TobeyTG/dashlane-omarchy/releases/tag/v0.1.0) (2026-08-30)

First public release: bar popup, native app with details sidebar, Omarchy menu — all on the official `dcli`.

### Features

* Omarchy menu plugin and Quickshell vault app on top of dcli ([4248c71](https://github.com/TobeyTG/dashlane-omarchy/commit/4248c71))
* **app:** locked screen with dcli login flow ([449034f](https://github.com/TobeyTG/dashlane-omarchy/commit/449034f))
* **copy:** pipe secrets through wl-copy, reveal, open URL, 30s auto-clear ([00de0a2](https://github.com/TobeyTG/dashlane-omarchy/commit/00de0a2))
* **security:** metadata-only listing, sensitive clipboard, pinned dcli, vault lock ([33fe689](https://github.com/TobeyTG/dashlane-omarchy/commit/33fe689))
* **app:** details sidebar with masked password, live OTP, note on demand ([846239d](https://github.com/TobeyTG/dashlane-omarchy/commit/846239d))
* **install:** wire dashlane-lock into hypridle; add uninstall.sh ([2aae455](https://github.com/TobeyTG/dashlane-omarchy/commit/2aae455))
* **bar:** bar widget plugin that opens the app ([1b9fda3](https://github.com/TobeyTG/dashlane-omarchy/commit/1b9fda3))
* **bar:** mini vault popup with search and copy, Spotify-style ([382b297](https://github.com/TobeyTG/dashlane-omarchy/commit/382b297))
* **app:** prefetch the selected entry's password for instant reveal/copy ([2a2e0b1](https://github.com/TobeyTG/dashlane-omarchy/commit/2a2e0b1))
* **plugin:** repo root is the Omarchy plugin (tobeytg.dashlane) ⚠ BREAKING ([af0cb76](https://github.com/TobeyTG/dashlane-omarchy/commit/af0cb76))
* **app:** shorter toasts, no duplicate notification, more keyboard shortcuts ([7acd97c](https://github.com/TobeyTG/dashlane-omarchy/commit/7acd97c))

### Bug Fixes

* **cli:** close stdin on dcli calls so a locked vault fails fast ([2783994](https://github.com/TobeyTG/dashlane-omarchy/commit/2783994))
* **cli:** keep save-master-password on, lock via dcli lock only ([c2770b0](https://github.com/TobeyTG/dashlane-omarchy/commit/c2770b0))
* **test:** make negated assertions fail under set -e ([8256d7a](https://github.com/TobeyTG/dashlane-omarchy/commit/8256d7a))
* **app:** keep the window from growing when the toast appears ([d55333d](https://github.com/TobeyTG/dashlane-omarchy/commit/d55333d))

### Performance

* one dcli call per copy; separate OTP fetcher; refresh OTP only at 30s boundary ([7489e41](https://github.com/TobeyTG/dashlane-omarchy/commit/7489e41))
* **copy:** resolve login vs email at the caller to avoid a retry ([52a991c](https://github.com/TobeyTG/dashlane-omarchy/commit/52a991c))
* **bar:** cache popup list with 5-min refresh; show fetching/copying feedback ([daf300b](https://github.com/TobeyTG/dashlane-omarchy/commit/daf300b))
