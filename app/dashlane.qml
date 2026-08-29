// Dashlane vault browser for Omarchy. Run: dashlane-app  (quickshell -p app/dashlane.qml)
// Layout + keyboard handling only; data lives in Vault.qml, colors in Theme.qml.
import QtQuick
import QtQuick.Layouts
import Quickshell

ShellRoot {
  property string toast: ""
  Connections { target: Vault; function onToast(m) { toast = m; toastTimer.restart() } }
  Timer { id: toastTimer; interval: 1200; onTriggered: toast = "" }

  FloatingWindow {
    title: "Dashlane"
    color: Theme.bg
    minimumSize: Qt.size(560, 420)
    implicitWidth: 960; implicitHeight: 600

    ColumnLayout {
      anchors.fill: parent; anchors.margins: 18; spacing: 12

      // search
      Rectangle {
        Layout.fillWidth: true; height: 44; radius: 10; color: Theme.bg2
        border.width: 1; border.color: search.activeFocus ? Theme.accent : Theme.bg3
        RowLayout { anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 10
          Text { text: ""; color: Theme.fg2; font.family: Theme.font; font.pixelSize: 16 }
          TextInput {
            id: search; Layout.fillWidth: true; color: Theme.fg; font.family: Theme.font; font.pixelSize: 15
            focus: true; clip: true; selectByMouse: true
            Text { text: "Search vault…"; visible: !search.text; color: Theme.fg2; font: search.font }
            onTextChanged: { Vault.query = text; list.currentIndex = 0 }
            Keys.onPressed: function (ev) {
              var e = list.currentItem ? list.currentItem.entry : null
              var ctrl = ev.modifiers & Qt.ControlModifier
              ev.accepted = true
              if (ev.key === Qt.Key_Down) list.incrementCurrentIndex()
              else if (ev.key === Qt.Key_Up) list.decrementCurrentIndex()
              else if (ev.key === Qt.Key_PageDown) list.currentIndex = Math.min(list.currentIndex + 10, list.count - 1)
              else if (ev.key === Qt.Key_PageUp) list.currentIndex = Math.max(list.currentIndex - 10, 0)
              else if (ev.key === Qt.Key_End && ctrl) list.currentIndex = list.count - 1
              else if (ev.key === Qt.Key_Home && ctrl) list.currentIndex = 0
              else if (ev.key === Qt.Key_Escape) { if (Vault.sidebarOpen) Vault.closeSidebar(); else Qt.quit() }
              else if (ev.key === Qt.Key_Right || ev.key === Qt.Key_Tab) Vault.select(e, true)
              else if (ev.key === Qt.Key_Left) Vault.closeSidebar()
              else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) { if (Vault.locked) Vault.startLogin(); else Vault.copy(e, "password") }
              else if (ctrl && ev.key === Qt.Key_L) Vault.copy(e, "login")
              else if (ctrl && ev.key === Qt.Key_O) Vault.copy(e, "otp")
              else if (ctrl && ev.key === Qt.Key_E) Vault.copy(e, "email")
              else if (ctrl && ev.key === Qt.Key_N) { Vault.select(e, true); Vault.toggleNote() }
              else if (ctrl && ev.key === Qt.Key_R) Vault.reload()
              else if (ctrl && ev.key === Qt.Key_S) Vault.reveal(e)
              else if (ctrl && ev.key === Qt.Key_U) Vault.openUrl(e)
              else ev.accepted = false
            }
          }
          Text { text: Vault.filtered.length + "/" + Vault.entries.length; color: Theme.fg2; font.family: Theme.font; font.pixelSize: 12 }
        }
      }

      LockedView { visible: Vault.locked; Layout.fillWidth: true; Layout.fillHeight: true }
      Text { visible: Vault.status !== ""; text: Vault.status; color: Theme.fg2; font.family: Theme.font; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.Wrap }

      RowLayout { visible: !Vault.locked; Layout.fillWidth: true; Layout.fillHeight: true; spacing: 12
        ListView {
          id: list
          Layout.fillWidth: true; Layout.fillHeight: true
          model: Vault.filtered; clip: true; spacing: 4; highlightMoveDuration: 80
          onCurrentItemChanged: if (Vault.sidebarOpen && currentItem) Vault.select(currentItem.entry, false)
          delegate: EntryRow { width: list.width; current: ListView.isCurrentItem
            onActivated: { list.currentIndex = index; Vault.select(entry, true) } }
        }
        Sidebar { Layout.preferredWidth: 300; Layout.fillHeight: true }
      }

      // footer
      RowLayout { Layout.fillWidth: true
        Text { text: "⏎ password  ^L login  ^E email  ^O otp  → details  ^S reveal  ^N note  ^U open  ^R reload  esc"; color: Theme.fg2; font.family: Theme.font; font.pixelSize: 11 }
        Item { Layout.fillWidth: true }
        Text { text: toast; color: Theme.green; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
      }
    }
  }
}
