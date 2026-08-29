import QtQuick
import qs.Commons
import qs.Ui

// Bar button: click opens the vault app, right-click summons the Passwords menu.
BarWidget {
  id: root
  moduleName: "dashlane-omarchy.vault"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰌾"
    slotSize: Style.bar.statusSlot
    fontSize: Style.font.caption
    tooltipText: "Dashlane vault"
    onPressed: if (root.bar) root.bar.run("dashlane-app")
  }
}
