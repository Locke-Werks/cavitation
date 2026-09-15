import QtQuick
import CAV 1.0
import QtQuick.Controls.Basic
import QtQuick.Layouts

CavDialog {
    id: root

    title: "NEW CONVERSATION"
    width: 440

    signal notImplemented(string message)

    ColumnLayout {
        width: root.width
        spacing: Theme.sp2

        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.sp4
            spacing: Theme.sp2

            Text {
                text: "Recipient (phone number or email)"
                color: Theme.fg3
                font.family: Theme.fontBody
                font.pixelSize: 11
            }

            CavTextField {
                id: target
                Layout.fillWidth: true
                placeholderText: "+15555550123 or someone@icloud.com"
            }

            // Stated plainly rather than failing silently on click: starting a
            // conversation needs an IDS handle-resolution call that is still
            // parked in the core (see rust/src/api/api.rs).
            Text {
                text: "Not wired yet. Resolving an address to an IDS handle is still " +
                      "parked in the protocol core, so new conversations have to start " +
                      "from another client for now."
                color: Theme.warning
                font.family: Theme.fontBody
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            CavButton {
                text: "START"
                primary: true
                implicitWidth: 90
                enabled: false
                onClicked: root.notImplemented("new chat: handle resolution not wired")
            }
        }
    }
}
