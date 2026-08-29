// Dashlane vault browser for Omarchy. Run: dashlane-app  (quickshell -p app/dashlane.qml)
// Reads the vault via `dcli p -o json`; never renders secrets, only copies them.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
  id: root
  property var entries: []
  property string status: "Loading vault…"
  property string toast: ""

  // --- theme: ~/.local/state/omarchy/current/theme/colors.toml ---
  property var theme: ({})
  function c(key, fallback) { return theme[key] || fallback }
  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/current/theme/colors.toml"
    blockLoading: true
    onLoaded: {
      var t = {}
      text().split("\n").forEach(function (l) {
        var m = l.match(/^\s*([a-z_]+)\s*=\s*"([^"]*)"/); if (m) t[m[1]] = m[2]
      })
      root.theme = t
    }
  }
  readonly property color bg: c("background", "#1e1e2e")
  readonly property color bg2: c("dark_background", "#181825")
  readonly property color bg3: c("lighter_background", "#313244")
  readonly property color fg: c("foreground", "#cdd6f4")
  readonly property color fg2: c("muted", "#6c7086")
  readonly property color accent: c("accent", "#89b4fa")
  readonly property color green: c("green", "#a6e3a1")
  readonly property string font: "CaskaydiaMono Nerd Font"

  // --- data ---
  Process {
    id: loader
    command: Quickshell.env("DASHLANE_JSON") ? ["cat", Quickshell.env("DASHLANE_JSON")] : ["dcli", "p", "-o", "json"]
    running: true
    stdout: StdioCollector { onStreamFinished: root.parse(text) }
    onExited: function (code) { if (code !== 0) root.status = "Vault locked or dcli failed — run `dcli sync` in a terminal, then press R" }
  }
  function parse(t) {
    try {
      var arr = JSON.parse(t)
      arr.sort(function (a, b) { return (a.title || a.url || "").toLowerCase() < (b.title || b.url || "").toLowerCase() ? -1 : 1 })
      root.entries = arr; root.status = ""
    } catch (e) { root.status = "Could not parse vault output" }
  }
  function reload() { root.status = "Loading vault…"; loader.running = false; loader.running = true }

  Process { id: copier; property string what
    stdout: StdioCollector {}
    onExited: function (code) { root.showToast(code === 0 ? "Copied " + copier.what : "Copy failed — vault locked?") } }
  function copy(entry, field) {
    if (!entry) return
    copier.what = field
    copier.command = ["dcli", "p", "id=" + entry.id, "-f", field, "-o", "clipboard"]
    copier.running = true
  }
  function showToast(m) { root.toast = m; toastTimer.restart() }
  Timer { id: toastTimer; interval: 1800; onTriggered: root.toast = "" }

  function matches(e, q) {
    if (!q) return true
    var hay = ((e.title || "") + " " + (e.url || "") + " " + (e.login || "") + " " + (e.email || "")).toLowerCase()
    return q.toLowerCase().split(/\s+/).every(function (w) { return hay.indexOf(w) >= 0 })
  }
  property var filtered: entries.filter(function (e) { return matches(e, search.text) })
  function host(e) { return (e.url || "").replace(/^https?:\/\//, "").replace(/^www\./, "").split("/")[0] }

  FloatingWindow {
    id: win
    title: "Dashlane"
    color: root.bg
    minimumSize: Qt.size(560, 420)
    implicitWidth: 720; implicitHeight: 520

    ColumnLayout {
      anchors.fill: parent; anchors.margins: 18; spacing: 12

      // search
      Rectangle {
        Layout.fillWidth: true; height: 44; radius: 10; color: root.bg2
        border.width: 1; border.color: search.activeFocus ? root.accent : root.bg3
        RowLayout { anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 10
          Text { text: ""; color: root.fg2; font.family: root.font; font.pixelSize: 16 }
          TextInput {
            id: search; Layout.fillWidth: true; color: root.fg; font.family: root.font; font.pixelSize: 15
            focus: true; clip: true; selectByMouse: true
            Text { text: "Search vault…"; visible: !search.text; color: root.fg2; font: search.font }
            onTextChanged: list.currentIndex = 0
            Keys.onPressed: function (ev) {
              var e = list.currentItem ? list.currentItem.entry : null
              if (ev.key === Qt.Key_Down) { list.incrementCurrentIndex(); ev.accepted = true }
              else if (ev.key === Qt.Key_Up) { list.decrementCurrentIndex(); ev.accepted = true }
              else if (ev.key === Qt.Key_Escape) Qt.quit()
              else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) root.copy(e, "password")
              else if (ev.modifiers & Qt.ControlModifier) {
                if (ev.key === Qt.Key_L) root.copy(e, "login")
                else if (ev.key === Qt.Key_O) root.copy(e, "otp")
                else if (ev.key === Qt.Key_R) root.reload()
                else return
                ev.accepted = true
              }
            }
          }
          Text { text: root.filtered.length + "/" + root.entries.length; color: root.fg2; font.family: root.font; font.pixelSize: 12 }
        }
      }

      // status
      Text { visible: root.status !== ""; text: root.status; color: root.fg2; font.family: root.font; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.Wrap }

      // list
      ListView {
        id: list
        Layout.fillWidth: true; Layout.fillHeight: true
        model: root.filtered; clip: true; spacing: 4
        highlightMoveDuration: 80
        delegate: Rectangle {
          required property var modelData
          required property int index
          property var entry: modelData
          width: list.width; height: 56; radius: 10
          color: ListView.isCurrentItem ? root.bg3 : (hover.hovered ? Qt.darker(root.bg3, 1.2) : "transparent")
          HoverHandler { id: hover }
          TapHandler { onTapped: list.currentIndex = index; onDoubleTapped: root.copy(entry, "password") }
          RowLayout { anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 10; spacing: 12
            Rectangle { width: 36; height: 36; radius: 8; color: root.bg2
              Text { anchors.centerIn: parent; color: root.accent; font.family: root.font; font.pixelSize: 15; font.bold: true
                text: ((entry.title || root.host(entry) || "?").charAt(0)).toUpperCase() } }
            ColumnLayout { Layout.fillWidth: true; spacing: 2
              Text { text: entry.title || root.host(entry) || "untitled"; color: root.fg; font.family: root.font; font.pixelSize: 14; elide: Text.ElideRight; Layout.fillWidth: true }
              Text { text: [entry.login || entry.email, root.host(entry)].filter(Boolean).join("  ·  "); color: root.fg2; font.family: root.font; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
            }
            Repeater {
              model: [["󰌾", "password"], ["󰀄", "login"]].concat(entry.otpSecret ? [["󰦝", "otp"]] : [])
              Rectangle { required property var modelData; width: 30; height: 30; radius: 7
                color: h2.hovered ? root.accent : "transparent"
                HoverHandler { id: h2 }
                TapHandler { onTapped: root.copy(entry, modelData[1]) }
                Text { anchors.centerIn: parent; text: modelData[0]; font.family: root.font; font.pixelSize: 14; color: h2.hovered ? root.bg : root.fg2 } }
            }
          }
        }
      }

      // footer
      RowLayout { Layout.fillWidth: true
        Text { text: "⏎ password   ^L login   ^O otp   ^R reload   esc quit"; color: root.fg2; font.family: root.font; font.pixelSize: 11 }
        Item { Layout.fillWidth: true }
        Text { text: root.toast; color: root.green; font.family: root.font; font.pixelSize: 12; font.bold: true }
      }
    }
  }
}
