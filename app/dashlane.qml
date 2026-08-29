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
  property bool locked: false

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
    // dashlane-list strips passwords/otp secrets before anything reaches this process
    command: ["dashlane-list"]
    running: true
    stdout: StdioCollector { onStreamFinished: root.parse(text) }
    onExited: function (code) { root.locked = code !== 0; if (code === 0) root.loggingIn = false; else root.status = "" }
  }
  // Opens a floating terminal running the official Dashlane CLI login. The launcher detaches,
  // so we can't wait on it — instead poll dcli every 3s while locked until the vault opens.
  property bool loggingIn: false
  Process {
    id: login
    command: ["omarchy-launch-floating-terminal-with-presentation", "dcli sync"]
    onStarted: root.loggingIn = true
  }
  Timer { running: root.locked && root.loggingIn; interval: 3000; repeat: true; onTriggered: { loader.running = false; loader.running = true } }
  function parse(t) {
    try {
      var arr = JSON.parse(t)
      arr.sort(function (a, b) { return (a.title || a.url || "").toLowerCase() < (b.title || b.url || "").toLowerCase() ? -1 : 1 })
      root.entries = arr; root.status = ""
      if (Quickshell.env("DASHLANE_TEST_OPEN") && arr.length) { root.select(root.filtered[1] || arr[0], true); root.togglePassword() }  // test hook for screenshots
    } catch (e) { root.status = "Could not parse vault output" }
  }
  function reload() { root.status = "Loading vault…"; root.locked = false; loader.running = false; loader.running = true }

  Process { id: copier; property string what; property var entry: ({})
    stdout: StdioCollector {}
    onExited: function (code) { root.showToast(code === 0 ? "Copied " + copier.what + " for " + root.host(copier.entry) + " · clears in 30s" : "Copy failed — vault locked?") } }
  // Sidebar details: secrets (password / otp / note) are fetched on demand via dashlane-field
  // and dropped when the sidebar closes, the entry changes, or after 10s (password).
  property var selected: null
  property bool sidebarOpen: false
  property string shownPassword: ""
  property string otpCode: ""
  property string noteText: ""
  function select(entry, open) { if (root.selected !== entry) { root.selected = entry; root.clearSecrets() } if (open) root.sidebarOpen = true }
  function clearSecrets() { root.shownPassword = ""; root.otpCode = ""; root.noteText = ""; otpTick.stop() }
  function closeSidebar() { root.sidebarOpen = false; root.clearSecrets() }
  Process { id: fielder; property string which
    stdout: StdioCollector { onStreamFinished: {
      var t = text.replace(/\n$/, "")
      if (fielder.which === "password") { root.shownPassword = t; pwTimer.restart() }
      else if (fielder.which === "otp") root.otpCode = t
      else if (fielder.which === "note") root.noteText = t
    } } }
  function fetch(which) {
    if (!root.selected || fielder.running) return
    fielder.which = which; fielder.command = ["dashlane-field", root.selected.id, which]; fielder.running = true
  }
  function togglePassword() { if (root.shownPassword) { root.shownPassword = ""; pwTimer.stop() } else root.fetch("password") }
  Timer { id: pwTimer; interval: 10000; onTriggered: root.shownPassword = "" }
  function reveal(entry) { root.select(entry, true); root.togglePassword() }
  function hideReveal() { root.clearSecrets() }
  // OTP: refetch at each 30s boundary while the sidebar shows an entry with OTP
  property int otpLeft: 30 - (Math.floor(Date.now() / 1000) % 30)
  Timer { id: otpTick; interval: 1000; repeat: true; running: root.sidebarOpen && !!root.selected && !!root.selected.hasOtp
    onTriggered: { root.otpLeft = 30 - (Math.floor(Date.now() / 1000) % 30); if (root.otpLeft === 30 || !root.otpCode) root.fetch("otp") } }
  function fmtDate(v) { var n = Number(v); if (!n) return "—"; return new Date(n * 1000).toLocaleString(Qt.locale(), "d MMM yyyy HH:mm") }
  Process { id: opener }
  function openUrl(entry) {
    if (!entry || !entry.url) return
    opener.command = ["xdg-open", entry.url.match(/^https?:\/\//) ? entry.url : "https://" + entry.url]
    opener.running = true; root.showToast("Opened " + root.host(entry))
  }
  function copy(entry, field) {
    if (!entry) return
    copier.what = field; copier.entry = entry
    copier.command = ["dashlane-copy", entry.id, field]
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
    implicitWidth: 960; implicitHeight: 600

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
            onTextChanged: { list.currentIndex = 0; if (root.sidebarOpen) root.select(list.currentItem ? list.currentItem.entry : null, false) }
            Keys.onPressed: function (ev) {
              var e = list.currentItem ? list.currentItem.entry : null
              if (ev.key === Qt.Key_Down) { list.incrementCurrentIndex(); ev.accepted = true }
              else if (ev.key === Qt.Key_Up) { list.decrementCurrentIndex(); ev.accepted = true }
              else if (ev.key === Qt.Key_Escape) { if (root.sidebarOpen) root.closeSidebar(); else Qt.quit() }
              else if (ev.key === Qt.Key_Right || ev.key === Qt.Key_Tab) { root.select(e, true); ev.accepted = true }
              else if (ev.key === Qt.Key_Left) { root.closeSidebar(); ev.accepted = true }
              else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) { if (root.locked) login.running = true; else root.copy(e, "password") }
              else if (ev.modifiers & Qt.ControlModifier) {
                if (ev.key === Qt.Key_L) root.copy(e, "login")
                else if (ev.key === Qt.Key_O) root.copy(e, "otp")
                else if (ev.key === Qt.Key_R) root.reload()
                else if (ev.key === Qt.Key_S) root.reveal(e)
                else if (ev.key === Qt.Key_U) root.openUrl(e)
                else return
                ev.accepted = true
              }
            }
          }
          Text { text: root.filtered.length + "/" + root.entries.length; color: root.fg2; font.family: root.font; font.pixelSize: 12 }
        }
      }

      // locked / not logged in
      Rectangle {
        visible: root.locked; Layout.fillWidth: true; Layout.fillHeight: true; radius: 12; color: root.bg2
        ColumnLayout { anchors.centerIn: parent; width: Math.min(parent.width - 48, 460); spacing: 14
          Text { text: "󰌾"; color: root.accent; font.family: root.font; font.pixelSize: 40; Layout.alignment: Qt.AlignHCenter }
          Text { text: "Vault locked"; color: root.fg; font.family: root.font; font.pixelSize: 18; font.bold: true; Layout.alignment: Qt.AlignHCenter }
          Text { Layout.fillWidth: true; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter; color: root.fg2; font.family: root.font; font.pixelSize: 12
            text: "Log in opens a terminal running the official Dashlane CLI (dcli sync). You enter your email, master password and device code there — this app never sees or stores them." }
          Rectangle { Layout.alignment: Qt.AlignHCenter; width: 180; height: 40; radius: 10; color: lh.hovered ? Qt.lighter(root.accent, 1.1) : root.accent
            HoverHandler { id: lh }
            TapHandler { onTapped: login.running = true }
            Text { anchors.centerIn: parent; text: root.loggingIn ? "Waiting for login…" : "Log in with dcli"; color: root.bg; font.family: root.font; font.pixelSize: 13; font.bold: true } }
        }
      }

      // status
      Text { visible: root.status !== ""; text: root.status; color: root.fg2; font.family: root.font; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.Wrap }

      // list + sidebar
      RowLayout { Layout.fillWidth: true; Layout.fillHeight: true; spacing: 12; visible: !root.locked
      ListView {
        id: list
        Layout.fillWidth: true; Layout.fillHeight: true
        model: root.filtered; clip: true; spacing: 4
        highlightMoveDuration: 80
        onCurrentItemChanged: if (root.sidebarOpen && currentItem) root.select(currentItem.entry, false)
        delegate: Rectangle {
          required property var modelData
          required property int index
          property var entry: modelData
          width: list.width; height: 56; radius: 10
          color: ListView.isCurrentItem ? root.bg3 : (hover.hovered ? Qt.darker(root.bg3, 1.2) : "transparent")
          HoverHandler { id: hover }
          TapHandler { onTapped: { list.currentIndex = index; root.select(entry, true) } onDoubleTapped: root.copy(entry, "password") }
          RowLayout { anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 10; spacing: 12
            Rectangle { width: 36; height: 36; radius: 8; color: root.bg2
              Text { anchors.centerIn: parent; color: root.accent; font.family: root.font; font.pixelSize: 15; font.bold: true
                text: ((entry.title || root.host(entry) || "?").charAt(0)).toUpperCase() } }
            ColumnLayout { Layout.fillWidth: true; spacing: 2
              Text { text: entry.title || root.host(entry) || "untitled"; color: root.fg; font.family: root.font; font.pixelSize: 14; elide: Text.ElideRight; Layout.fillWidth: true }
              Text { text: [entry.login || entry.email, root.host(entry)].filter(Boolean).join("  ·  "); color: root.fg2; font.family: root.font; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
            }
            Repeater {
              model: [["󰌾", "password"], ["󰀄", "login"]].concat(entry.hasOtp ? [["󰦝", "otp"]] : []).concat([["󰈈", "reveal"]]).concat(entry.url ? [["󰖟", "open"]] : [])
              Rectangle { required property var modelData; width: 30; height: 30; radius: 7
                color: h2.hovered ? root.accent : "transparent"
                HoverHandler { id: h2 }
                TapHandler { onTapped: modelData[1] === "reveal" ? root.reveal(entry) : modelData[1] === "open" ? root.openUrl(entry) : root.copy(entry, modelData[1]) }
                Text { anchors.centerIn: parent; text: modelData[0]; font.family: root.font; font.pixelSize: 14; color: h2.hovered ? root.bg : root.fg2 } }
            }
          }
        }
      }


      // sidebar: entry details, like the extension's detail pane
      Rectangle {
        id: side
        visible: root.sidebarOpen && !!root.selected
        Layout.preferredWidth: 300; Layout.fillHeight: true; radius: 12; color: root.bg2
        property var e: root.selected || ({})
        component Field: ColumnLayout {
          property string label; property string value; property string mono: ""; property bool secret: false
          property var onCopy: null; property var onToggle: null; property string copyIcon: "󰆏"; property bool shown: false; property bool visibleWhen: true
          visible: visibleWhen; spacing: 2; Layout.fillWidth: true
          Text { text: label; color: root.fg2; font.family: root.font; font.pixelSize: 10; font.capitalization: Font.AllUppercase }
          RowLayout { Layout.fillWidth: true; spacing: 6
            Text { Layout.fillWidth: true; text: secret && !shown ? "••••••••••••" : (value || "—"); color: value ? root.fg : root.fg2
              font.family: root.font; font.pixelSize: mono ? 15 : 13; font.bold: !!mono; elide: Text.ElideMiddle; wrapMode: mono ? Text.NoWrap : Text.Wrap }
            Repeater { model: [onToggle ? [shown ? "󰈉" : "󰈈", onToggle] : null, onCopy && value ? [copyIcon, onCopy] : null].filter(Boolean)
              Rectangle { required property var modelData; width: 26; height: 26; radius: 6; color: hh.hovered ? root.accent : "transparent"
                HoverHandler { id: hh } TapHandler { onTapped: modelData[1]() }
                Text { anchors.centerIn: parent; text: modelData[0]; font.family: root.font; font.pixelSize: 13; color: hh.hovered ? root.bg : root.fg2 } } }
          }
        }
        Flickable { anchors.fill: parent; anchors.margins: 16; contentHeight: col.height; clip: true; flickableDirection: Flickable.VerticalFlick
          ColumnLayout { id: col; width: parent.width; spacing: 14
            RowLayout { spacing: 10; Layout.fillWidth: true
              Rectangle { width: 40; height: 40; radius: 10; color: root.bg3
                Text { anchors.centerIn: parent; color: root.accent; font.family: root.font; font.pixelSize: 18; font.bold: true; text: ((side.e.title || root.host(side.e) || "?").charAt(0)).toUpperCase() } }
              ColumnLayout { Layout.fillWidth: true; spacing: 0
                Text { text: side.e.title || root.host(side.e) || "untitled"; color: root.fg; font.family: root.font; font.pixelSize: 15; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                Text { text: root.host(side.e); color: root.fg2; font.family: root.font; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true } }
              Rectangle { width: 26; height: 26; radius: 6; color: xh.hovered ? root.bg3 : "transparent"; HoverHandler { id: xh } TapHandler { onTapped: root.closeSidebar() }
                Text { anchors.centerIn: parent; text: "󰅖"; color: root.fg2; font.family: root.font; font.pixelSize: 13 } }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: root.bg3 }
            Field { label: "Website"; value: side.e.url || ""; copyIcon: "󰖟"; onCopy: function () { root.openUrl(side.e) } }
            Field { label: "Login"; value: side.e.login || ""; visibleWhen: !!side.e.login; onCopy: function () { root.copy(side.e, "login") } }
            Field { label: "Email"; value: side.e.email || ""; visibleWhen: !!side.e.email; onCopy: function () { root.copy(side.e, "email") } }
            Field { label: "Secondary login"; value: side.e.secondaryLogin || ""; visibleWhen: !!side.e.secondaryLogin }
            Field { label: "Password"; secret: true; shown: !!root.shownPassword; value: root.shownPassword || "x"; mono: root.shownPassword ? "y" : ""
              onToggle: function () { root.togglePassword() }; onCopy: function () { root.copy(side.e, "password") } }
            ColumnLayout { visible: !!side.e.hasOtp; spacing: 4; Layout.fillWidth: true
              Field { label: "One-time code"; value: root.otpCode ? root.otpCode.replace(/(\d{3})(?=\d)/g, "$1 ") : ""; mono: "y"; onCopy: function () { root.copy(side.e, "otp") } }
              Rectangle { Layout.fillWidth: true; height: 3; radius: 2; color: root.bg3
                Rectangle { width: parent.width * root.otpLeft / 30; height: parent.height; radius: 2; color: root.otpLeft <= 5 ? root.c("red", "#f38ba8") : root.green
                  Behavior on width { NumberAnimation { duration: 900 } } } }
            }
            Field { label: "Note"; visibleWhen: !!side.e.hasNote; value: root.noteText; secret: true; shown: !!root.noteText
              onToggle: function () { if (root.noteText) root.noteText = ""; else root.fetch("note") } }
            Rectangle { Layout.fillWidth: true; height: 1; color: root.bg3 }
            Field { label: "Category"; value: side.e.category || ""; visibleWhen: !!side.e.category }
            RowLayout { Layout.fillWidth: true; spacing: 12
              Field { label: "Modified"; value: root.fmtDate(side.e.modificationDatetime) }
              Field { label: "Last used"; value: root.fmtDate(side.e.lastUse) } }
            RowLayout { Layout.fillWidth: true; spacing: 12
              Field { label: "Uses"; value: String(side.e.numberUse || 0) }
              ColumnLayout { spacing: 4; Layout.fillWidth: true
                Text { text: "STRENGTH " + (Number(side.e.strength) || 0) + "%"; color: root.fg2; font.family: root.font; font.pixelSize: 10 }
                Rectangle { Layout.fillWidth: true; height: 4; radius: 2; color: root.bg3
                  Rectangle { property real p: (Number(side.e.strength) || 0) / 100; width: parent.width * p; height: parent.height; radius: 2
                    color: p < 0.4 ? root.c("red", "#f38ba8") : p < 0.7 ? root.c("yellow", "#f9e2af") : root.green } } } }
            Text { text: "Password history isn't exposed by the Dashlane CLI."; color: root.fg2; font.family: root.font; font.pixelSize: 10; wrapMode: Text.Wrap; Layout.fillWidth: true }
          }
        }
      }
      }
      // footer
      RowLayout { Layout.fillWidth: true
        Text { text: "⏎ password   ^L login   ^O otp   → details   ^S reveal   ^U open   ^R reload   esc"; color: root.fg2; font.family: root.font; font.pixelSize: 11 }
        Item { Layout.fillWidth: true }
        Text { text: root.toast; color: root.green; font.family: root.font; font.pixelSize: 12; font.bold: true }
      }
    }
  }
}
