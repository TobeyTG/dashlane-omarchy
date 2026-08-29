import QtQuick
import QtQuick.Layouts

// Shown when dcli can't open the vault. Login happens in dcli's own terminal prompt.
Rectangle {
  radius: 12; color: Theme.bg2
  ColumnLayout { anchors.centerIn: parent; width: Math.min(parent.width - 48, 460); spacing: 14
    Text { text: "󰌾"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 40; Layout.alignment: Qt.AlignHCenter }
    Text { text: "Vault locked"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 18; font.bold: true; Layout.alignment: Qt.AlignHCenter }
    Text { Layout.fillWidth: true; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter; color: Theme.fg2; font.family: Theme.font; font.pixelSize: 12
      text: "Log in opens a terminal running the official Dashlane CLI (dcli sync). You enter your email, master password and device code there — this app never sees or stores them." }
    Rectangle { Layout.alignment: Qt.AlignHCenter; width: 180; height: 40; radius: 10; color: hover.hovered ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
      HoverHandler { id: hover }
      TapHandler { onTapped: Vault.startLogin() }
      Text { anchors.centerIn: parent; text: Vault.loggingIn ? "Waiting for login…" : "Log in with dcli"; color: Theme.bg; font.family: Theme.font; font.pixelSize: 13; font.bold: true } }
  }
}
