import QtQuick

Rectangle {
  id: root
  property string icon
  property int size: 30
  signal clicked
  width: size; height: size; radius: size / 4
  color: hover.hovered ? Theme.accent : "transparent"
  HoverHandler { id: hover }
  TapHandler { onTapped: root.clicked() }
  Text { anchors.centerIn: parent; text: root.icon; font.family: Theme.font; font.pixelSize: size / 2; color: hover.hovered ? Theme.bg : Theme.fg2 }
}
