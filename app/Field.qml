import QtQuick
import QtQuick.Layouts

// One labelled row in the sidebar. `secret` rows show dots until `shown`.
ColumnLayout {
  id: root
  property string label
  property string value
  property bool mono: false
  property bool secret: false
  property bool shown: false
  property string actionIcon: "󰆏"
  property bool hasAction: false
  property bool hasToggle: false
  signal action
  signal toggle
  spacing: 2; Layout.fillWidth: true
  Text { text: root.label; color: Theme.fg2; font.family: Theme.font; font.pixelSize: 10; font.capitalization: Font.AllUppercase }
  RowLayout { Layout.fillWidth: true; spacing: 6
    Text { Layout.fillWidth: true; Layout.preferredWidth: 0; textFormat: Text.PlainText; text: root.secret && !root.shown ? "••••••••••••" : (root.value || "—"); color: root.value ? Theme.fg : Theme.fg2
      font.family: Theme.font; font.pixelSize: root.mono ? 15 : 13; font.bold: root.mono; elide: Text.ElideMiddle; wrapMode: root.mono ? Text.NoWrap : Text.Wrap }
    IconButton { visible: root.hasToggle; size: 26; icon: root.shown ? "󰈉" : "󰈈"; onClicked: root.toggle() }
    IconButton { visible: root.hasAction && !!root.value; size: 26; icon: root.actionIcon; onClicked: root.action() }
  }
}
