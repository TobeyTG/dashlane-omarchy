import QtQuick
import QtQuick.Layouts

// Entry details, like the browser extension's detail pane. Secrets come from Vault on demand.
Rectangle {
  id: root
  readonly property var e: Vault.selected || ({})
  visible: Vault.sidebarOpen && !!Vault.selected
  radius: 12; color: Theme.bg2
  Layout.minimumWidth: 300; Layout.maximumWidth: 300   // fixed: long values elide, they never widen the window

  Flickable { anchors.fill: parent; anchors.margins: 16; contentHeight: col.height; clip: true; flickableDirection: Flickable.VerticalFlick
    ColumnLayout { id: col; width: parent.width; spacing: 14
      RowLayout { spacing: 10; Layout.fillWidth: true
        Rectangle { width: 40; height: 40; radius: 10; color: Theme.bg3
          Text { anchors.centerIn: parent; color: Theme.accent; font.family: Theme.font; font.pixelSize: 18; font.bold: true; textFormat: Text.PlainText; text: Vault.initial(root.e) } }
        ColumnLayout { Layout.fillWidth: true; spacing: 0
          Text { textFormat: Text.PlainText; text: Vault.name(root.e); color: Theme.fg; font.family: Theme.font; font.pixelSize: 15; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
          Text { textFormat: Text.PlainText; text: Vault.host(root.e); color: Theme.fg2; font.family: Theme.font; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true } }
        IconButton { size: 26; icon: "󰅖"; onClicked: Vault.closeSidebar() }
      }
      Rectangle { Layout.fillWidth: true; height: 1; color: Theme.bg3 }

      Field { label: "Website"; value: root.e.url || ""; actionIcon: "󰖟"; hasAction: true; onAction: Vault.openUrl(root.e) }
      Field { label: "Login"; value: root.e.login || ""; visible: !!root.e.login; hasAction: true; onAction: Vault.copy(root.e, "login") }
      Field { label: "Email"; value: root.e.email || ""; visible: !!root.e.email; hasAction: true; onAction: Vault.copy(root.e, "email") }
      Field { label: "Secondary login"; value: root.e.secondaryLogin || ""; visible: !!root.e.secondaryLogin }
      Field { label: "Password"; secret: true; shown: !!Vault.shownPassword || Vault.fetching; value: Vault.shownPassword || (Vault.fetching ? "fetching…" : "•"); mono: !!Vault.shownPassword
        hasToggle: true; onToggle: Vault.togglePassword(); hasAction: true; onAction: Vault.copy(root.e, "password") }
      ColumnLayout { visible: !!root.e.hasOtp; spacing: 4; Layout.fillWidth: true
        Field { label: "One-time code"; secret: true; shown: !!Vault.otpCode; value: Vault.otpCode.replace(/(\d{3})(?=\d)/g, "$1 ") || (Vault.otpShown ? "fetching…" : "•"); mono: !!Vault.otpCode
          hasToggle: true; onToggle: Vault.toggleOtp(); hasAction: true; onAction: Vault.copy(root.e, "otp") }
        Rectangle { Layout.fillWidth: true; height: 3; radius: 2; color: Theme.bg3; visible: Vault.otpShown
          Rectangle { width: parent.width * Vault.otpLeft / 30; height: parent.height; radius: 2; color: Vault.otpLeft <= 5 ? Theme.red : Theme.green
            Behavior on width { NumberAnimation { duration: 900 } } } }
      }
      Field { label: "Note"; visible: !!root.e.hasNote; value: Vault.noteText || (Vault.fetching ? "fetching…" : ""); secret: true; shown: !!Vault.noteText || Vault.fetching; hasToggle: true; onToggle: Vault.toggleNote() }
      Rectangle { Layout.fillWidth: true; height: 1; color: Theme.bg3 }

      Field { label: "Category"; value: root.e.category || ""; visible: !!root.e.category }
      RowLayout { Layout.fillWidth: true; spacing: 12
        Field { label: "Modified"; value: Vault.fmtDate(root.e.modificationDatetime) }
        Field { label: "Last used"; value: Vault.fmtDate(root.e.lastUse) } }
      RowLayout { Layout.fillWidth: true; spacing: 12
        Field { label: "Uses"; value: String(root.e.numberUse || 0) }
        ColumnLayout { spacing: 4; Layout.fillWidth: true
          Text { text: "STRENGTH " + (Number(root.e.strength) || 0) + "%"; color: Theme.fg2; font.family: Theme.font; font.pixelSize: 10 }
          Rectangle { Layout.fillWidth: true; height: 4; radius: 2; color: Theme.bg3
            Rectangle { readonly property real p: (Number(root.e.strength) || 0) / 100; width: parent.width * p; height: parent.height; radius: 2
              color: p < 0.4 ? Theme.red : p < 0.7 ? Theme.yellow : Theme.green } } } }
      Text { text: "Password history isn't exposed by the Dashlane CLI."; color: Theme.fg2; font.family: Theme.font; font.pixelSize: 10; wrapMode: Text.Wrap; Layout.fillWidth: true }
    }
  }
}
