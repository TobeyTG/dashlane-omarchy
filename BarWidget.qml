import QtQuick
import qs.Commons
import qs.Ui

// Bar button: left-click toggles the mini vault popup, middle-click opens the full app.
BarWidget {
  id: root
  moduleName: "tobeytg.dashlane"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function injectPanel() {
    var t = panelLoader.item; if (!t) return
    t.bar = root.bar; t.settings = root.settings; t.anchorItem = button; t.hostWidget = root
  }
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  function open() { if (panelLoader.item) panelLoader.item.openFromHotkey() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }
  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader { id: panelLoader; active: true; source: Qt.resolvedUrl("Panel.qml"); visible: false
    onLoaded: { root.injectPanel(); Qt.callLater(root.injectPanel) } }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰌾"
    slotSize: Style.bar.statusSlot
    fontSize: Style.font.caption
    tooltipText: "Dashlane"
    onPressed: function (b) {
      if (!panelLoader.item) return
      if (b === Qt.MiddleButton) panelLoader.item.openApp()
      else panelLoader.item.toggle()
    }
  }
}
