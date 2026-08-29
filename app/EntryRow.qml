import QtQuick
import QtQuick.Layouts

// One vault entry in the list. Click selects + opens details, double-click copies the password.
Rectangle {
  id: root
  required property var modelData
  required property int index
  readonly property var entry: modelData
  property bool current: false
  signal activated
  height: 56; radius: 10
  color: current ? Theme.bg3 : (hover.hovered ? Qt.darker(Theme.bg3, 1.2) : "transparent")
  HoverHandler { id: hover }
  TapHandler { onTapped: root.activated(); onDoubleTapped: Vault.copy(root.entry, "password") }
  RowLayout { anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 10; spacing: 12
    Rectangle { width: 36; height: 36; radius: 8; color: Theme.bg2
      Text { anchors.centerIn: parent; color: Theme.accent; font.family: Theme.font; font.pixelSize: 15; font.bold: true; text: Vault.initial(root.entry) } }
    ColumnLayout { Layout.fillWidth: true; spacing: 2
      Text { text: Vault.name(root.entry); color: Theme.fg; font.family: Theme.font; font.pixelSize: 14; elide: Text.ElideRight; Layout.fillWidth: true }
      Text { text: [root.entry.login || root.entry.email, Vault.host(root.entry)].filter(Boolean).join("  ·  "); color: Theme.fg2; font.family: Theme.font; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
    }
    IconButton { icon: "󰌾"; onClicked: Vault.copy(root.entry, "password") }
    IconButton { icon: "󰀄"; onClicked: Vault.copy(root.entry, "login") }
    IconButton { icon: "󰦝"; visible: !!root.entry.hasOtp; onClicked: Vault.copy(root.entry, "otp") }
    IconButton { icon: "󰈈"; onClicked: Vault.reveal(root.entry) }
    IconButton { icon: "󰖟"; visible: !!root.entry.url; onClicked: Vault.openUrl(root.entry) }
  }
}
