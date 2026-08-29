import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Mini popup under the bar icon: search, ⏎ copies the password, ^L login, ^O OTP,
// "Open app" launches the full window. Metadata only (dashlane-list); copies via dashlane-copy.
Panel {
  id: root
  moduleName: "tobeytg.dashlane"
  ipcTarget: "tobeytg.dashlane"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  // Scripts live next to this file (the repo root is the plugin), so no PATH setup is needed.
  readonly property string pluginDir: Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "")
  readonly property string binDir: pluginDir + "bin/"
  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  property var entries: []
  property bool locked: false
  property int cursor: 0
  property string toast: ""
  readonly property int maxRows: 8
  readonly property var filtered: {
    var q = search.text.toLowerCase().split(/\s+/).filter(Boolean)
    return entries.filter(function (e) {
      var hay = [e.title, e.url, e.login, e.email].join(" ").toLowerCase()
      return q.every(function (w) { return hay.indexOf(w) >= 0 })
    }).slice(0, maxRows)
  }

  // Keep the cached list between opens (dashlane-list costs ~0.65s); refresh in the background
  // when it's older than 5 minutes or empty, so the popup is instant with the last known entries.
  property double loadedAt: 0
  function open() {
    root.controller.show(); search.text = ""; cursor = 0
    if (!entries.length || Date.now() - loadedAt > 300000) refresh()
  }
  function openFromHotkey() { open() }
  function close() { root.controller.hide() }
  function toggle() { root.opened ? close() : open() }
  function refresh() { loader.running = false; loader.running = true }
  function host(e) { return ((e && e.url) || "").replace(/^https?:\/\//, "").replace(/^www\./, "").split("/")[0] }
  function name(e) { return (e && (e.title || host(e))) || "untitled" }
  function current() { return filtered[Math.max(0, Math.min(cursor, filtered.length - 1))] || null }
  function copy(field) {
    var e = current(); if (!e) return
    if (field === "login" && !e.login && e.email) field = "email"
    copier.field = field; copier.command = [binDir + "dashlane-copy", "--quiet", e.id, field]; copier.running = true; showToast("Copying…")
  }
  function openApp() { close(); if (bar) bar.run(binDir + "dashlane-app") }
  function finishSetup() { close(); if (bar) bar.run("omarchy-launch-floating-terminal-with-presentation " + pluginDir + "install.sh") }
  readonly property bool setupDone: dcliCheck.exitCode === 0
  Process { id: dcliCheck; property int exitCode: 0; command: ["sh", "-c", "command -v dcli"]; running: true; onExited: function (c) { exitCode = c } }
  function showToast(m) { toast = m; toastTimer.restart() }

  Process { id: loader; command: [root.binDir + "dashlane-list"]
    stdout: StdioCollector { onStreamFinished: { try { root.entries = JSON.parse(text).sort(function (a, b) { return root.name(a).toLowerCase() < root.name(b).toLowerCase() ? -1 : 1 }); root.loadedAt = Date.now() } catch (e) {} } }
    onExited: function (code) { root.locked = code !== 0; if (code !== 0) root.entries = [] } }
  Process { id: copier; property string field; stdout: StdioCollector {}
    onExited: function (code) { if (code === 0) { root.showToast("Copied " + copier.field); closeTimer.restart() } else root.showToast("Copy failed") } }
  Timer { id: toastTimer; interval: 1200; onTriggered: root.toast = "" }
  Timer { id: closeTimer; interval: 600; onTriggered: root.close() }

  IpcHandler { target: "tobeytg.dashlane"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() } }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: search
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      width: parent.width
      spacing: Style.space(8)

      TextField {
        id: search
        width: parent.width
        placeholderText: root.locked ? "Vault locked" : (loader.running && !root.entries.length ? "Loading vault…" : "Search vault…")
        enabled: !root.locked
        foreground: root.fg
        font.family: root.fontFamily
        onTextChanged: root.cursor = 0
        Keys.onPressed: function (ev) {
          var ctrl = ev.modifiers & Qt.ControlModifier
          ev.accepted = true
          if (ev.key === Qt.Key_Escape) root.close()
          else if (ev.key === Qt.Key_Down) root.cursor = Math.min(root.cursor + 1, root.filtered.length - 1)
          else if (ev.key === Qt.Key_Up) root.cursor = Math.max(root.cursor - 1, 0)
          else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) { if (root.locked) root.openApp(); else root.copy("password") }
          else if (ctrl && ev.key === Qt.Key_L) root.copy("login")
          else if (ctrl && ev.key === Qt.Key_O) root.copy("otp")
          else if (ctrl && ev.key === Qt.Key_Return) root.openApp()
          else ev.accepted = false
        }
      }

      Text { visible: root.locked; width: parent.width; wrapMode: Text.Wrap; color: Qt.darker(root.fg, 1.4); font.family: root.fontFamily; font.pixelSize: Style.font.caption
        text: root.setupDone ? "Open the app to log in with the official Dashlane CLI." : "First run: installs the official Dashlane CLI (pinned), the vault-lock hook and the menu." }
      Button { visible: root.locked && !root.setupDone; text: "Finish setup"; onClicked: root.finishSetup() }

      Repeater {
        model: root.filtered
        Rectangle {
          required property var modelData
          required property int index
          width: column.width; height: Style.space(40); radius: Style.space(8)
          color: index === root.cursor ? Style.selectedFillFor(root.fg, Color.accent) : (rowHover.hovered ? Style.hoverFillFor(root.fg, Color.accent) : "transparent")
          HoverHandler { id: rowHover; onHoveredChanged: if (hovered) root.cursor = index }
          TapHandler { onTapped: { root.cursor = index; root.copy("password") } }
          Row { anchors.fill: parent; anchors.leftMargin: Style.space(10); anchors.rightMargin: Style.space(10); spacing: Style.space(10)
            Text { anchors.verticalCenter: parent.verticalCenter; text: "󰌾"; color: Color.accent; font.family: root.fontFamily; font.pixelSize: Style.font.caption + 2 }
            Column { anchors.verticalCenter: parent.verticalCenter; width: parent.width - Style.space(30); spacing: 0
              Text { width: parent.width; elide: Text.ElideRight; text: root.name(modelData); color: root.fg; font.family: root.fontFamily; font.pixelSize: Style.font.caption + 2 }
              Text { width: parent.width; elide: Text.ElideRight; text: [modelData.login || modelData.email, root.host(modelData)].filter(Boolean).join(" · "); color: Qt.darker(root.fg, 1.5); font.family: root.fontFamily; font.pixelSize: Style.font.caption } }
          }
        }
      }
      Text { visible: !root.locked && root.filtered.length === 0 && root.entries.length > 0; text: "No matches"; color: Qt.darker(root.fg, 1.5); font.family: root.fontFamily; font.pixelSize: Style.font.caption }

      PanelSeparator { width: parent.width }
      Row { width: parent.width; spacing: Style.space(8)
        Text { anchors.verticalCenter: parent.verticalCenter; width: parent.width - openBtn.width - Style.space(8); elide: Text.ElideRight
          text: root.toast || "⏎ password  ^L login  ^O otp  ^⏎ app"; color: root.toast ? Color.accent : Qt.darker(root.fg, 1.5); font.family: root.fontFamily; font.pixelSize: Style.font.caption }
        Button { id: openBtn; text: "Open app"; onClicked: root.openApp() }
      }
    }
  }
}
