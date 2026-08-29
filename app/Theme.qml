pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Colors from the active Omarchy theme (~/.local/state/omarchy/current/theme/colors.toml),
// with Catppuccin fallbacks when the file is missing (non-Omarchy systems).
Singleton {
  id: root
  property var colors: ({})
  function c(key, fallback) { return colors[key] || fallback }

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/current/theme/colors.toml"
    blockLoading: true
    onLoaded: {
      var t = {}
      text().split("\n").forEach(function (l) {
        var m = l.match(/^\s*([a-z_]+)\s*=\s*"([^"]*)"/); if (m) t[m[1]] = m[2]
      })
      root.colors = t
    }
  }

  readonly property color bg: c("background", "#1e1e2e")
  readonly property color bg2: c("dark_background", "#181825")
  readonly property color bg3: c("lighter_background", "#313244")
  readonly property color fg: c("foreground", "#cdd6f4")
  readonly property color fg2: c("muted", "#6c7086")
  readonly property color accent: c("accent", "#89b4fa")
  readonly property color green: c("green", "#a6e3a1")
  readonly property color yellow: c("yellow", "#f9e2af")
  readonly property color red: c("red", "#f38ba8")
  readonly property string font: "CaskaydiaMono Nerd Font"
}
