# Changelog

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
