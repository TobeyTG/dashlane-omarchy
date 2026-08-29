pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// All vault access. Nothing here talks to dcli directly: the bin/ scripts do, and they
// strip secrets (dashlane-list) or hand over exactly one field on demand (dashlane-field).
// Secrets held here (shownPassword, otpCode, noteText) are cleared on entry change,
// sidebar close, or timeout.
Singleton {
  id: root

  // ---- list ----
  property var entries: []
  property string query: ""
  property string status: "Loading vault…"
  property bool locked: false
  property bool loggingIn: false
  readonly property var filtered: entries.filter(function (e) { return matches(e, query) })

  Process {
    id: loader
    command: ["dashlane-list"]
    running: true
    stdout: StdioCollector { onStreamFinished: root.parse(text) }
    onExited: function (code) { root.locked = code !== 0; if (code === 0) root.loggingIn = false; else root.status = "" }
  }
  function parse(t) {
    try {
      var arr = JSON.parse(t)
      arr.sort(function (a, b) { return root.name(a).toLowerCase() < root.name(b).toLowerCase() ? -1 : 1 })
      root.entries = arr; root.status = ""
      if (Quickshell.env("DASHLANE_TEST_OPEN") && arr.length) { root.select(arr.find(function (e) { return e.hasOtp }) || arr[0], true); root.togglePassword() }  // screenshot hook
    } catch (e) { root.status = "Could not parse vault output" }
  }
  function reload() { root.status = "Loading vault…"; root.locked = false; loader.running = false; loader.running = true }

  // Login opens a floating terminal running the official CLI. The launcher detaches, so we
  // poll dcli every 3s while locked until the vault opens.
  Process { id: login; command: ["omarchy-launch-floating-terminal-with-presentation", "dcli sync"]; onStarted: root.loggingIn = true }
  function startLogin() { login.running = true }
  Timer { running: root.locked && root.loggingIn; interval: 3000; repeat: true; onTriggered: root.reload() }

  // ---- selection / sidebar ----
  property var selected: null
  property bool sidebarOpen: false
  property string shownPassword: ""
  property string otpCode: ""
  property string noteText: ""
  function select(entry, open) {
    if (root.selected !== entry) { root.selected = entry; root.clearSecrets() }
    if (open && entry) root.sidebarOpen = true
  }
  function clearSecrets() { root.shownPassword = ""; root.otpCode = ""; root.noteText = ""; pwTimer.stop() }
  function closeSidebar() { root.sidebarOpen = false; root.clearSecrets() }

  // Two processes so a slow/looping OTP refresh can never block a password/note reveal.
  Process { id: fielder; property string which
    stdout: StdioCollector { onStreamFinished: {
      var t = text.replace(/\n$/, "")
      if (fielder.which === "password") { root.shownPassword = t; pwTimer.restart() }
      else if (fielder.which === "note") root.noteText = t
    } } }
  Process { id: otpFetcher; stdout: StdioCollector { onStreamFinished: root.otpCode = text.replace(/\n$/, "") } }
  function fetch(which) {
    if (!root.selected) return
    if (which === "otp") { if (!otpFetcher.running) { otpFetcher.command = ["dashlane-field", root.selected.id, "otp"]; otpFetcher.running = true } return }
    if (fielder.running) return
    fielder.which = which; fielder.command = ["dashlane-field", root.selected.id, which]; fielder.running = true
  }
  readonly property bool fetching: fielder.running
  function togglePassword() { if (root.shownPassword) { root.shownPassword = ""; pwTimer.stop() } else root.fetch("password") }
  function toggleNote() { if (root.noteText) root.noteText = ""; else root.fetch("note") }
  function reveal(entry) { root.select(entry, true); root.togglePassword() }
  Timer { id: pwTimer; interval: 10000; onTriggered: root.shownPassword = "" }

  // OTP: fetch once when shown, then only at each 30s boundary (dcli costs ~0.6s per call).
  property int otpLeft: 30
  Timer { interval: 1000; repeat: true; triggeredOnStart: true
    running: root.sidebarOpen && !!root.selected && !!root.selected.hasOtp
    onRunningChanged: if (running) root.fetch("otp")
    onTriggered: { var left = 30 - (Math.floor(Date.now() / 1000) % 30); if (left > root.otpLeft) root.fetch("otp"); root.otpLeft = left } }

  // ---- actions ----
  signal toast(string message)
  Process { id: copier; property string what; property var entry: ({})
    stdout: StdioCollector {}
    onExited: function (code) { root.toast(code === 0 ? "Copied " + copier.what + " for " + root.host(copier.entry) + " · clears in 30s" : "Copy failed — vault locked?") } }
  function copy(entry, field) {
    if (!entry) return
    if (field === "login" && !entry.login && entry.email) field = "email"   // skip dcli's failing login lookup
    copier.what = field; copier.entry = entry; copier.command = ["dashlane-copy", entry.id, field, root.host(entry)]; copier.running = true; root.toast("Copying " + field + "…")
  }
  Process { id: opener }
  function openUrl(entry) {
    if (!entry || !entry.url) return
    opener.command = ["xdg-open", /^https?:\/\//.test(entry.url) ? entry.url : "https://" + entry.url]
    opener.running = true; root.toast("Opened " + root.host(entry))
  }

  // ---- helpers ----
  function host(e) { return ((e && e.url) || "").replace(/^https?:\/\//, "").replace(/^www\./, "").split("/")[0] }
  function name(e) { return (e && (e.title || root.host(e))) || "untitled" }
  function initial(e) { return root.name(e).charAt(0).toUpperCase() }
  function matches(e, q) {
    if (!q) return true
    var hay = [e.title, e.url, e.login, e.email].join(" ").toLowerCase()
    return q.toLowerCase().split(/\s+/).every(function (w) { return hay.indexOf(w) >= 0 })
  }
  function fmtDate(v) { var n = Number(v); return n ? new Date(n * 1000).toLocaleString(Qt.locale(), "d MMM yyyy HH:mm") : "—" }
}
