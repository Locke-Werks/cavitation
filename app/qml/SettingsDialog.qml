import QtQuick
import CAV 1.0
import QtQuick.Controls.Basic
import QtQuick.Layouts

CavDialog {
    id: root

    title: "SETTINGS"
    width: 520

    onOpened: handleRepeater.model = Core.handles()

    component InfoRow: RowLayout {
        id: infoRow
        property string label: ""
        property string value: ""
        spacing: Theme.sp3
        Layout.fillWidth: true

        Text {
            text: infoRow.label
            color: Theme.fg4
            font.family: Theme.fontMono
            font.pixelSize: 11
            Layout.preferredWidth: 92
        }
        Text {
            text: infoRow.value
            color: Theme.fg2
            font.family: Theme.fontMono
            font.pixelSize: 11
            elide: Text.ElideMiddle
            Layout.fillWidth: true
        }
    }

    ColumnLayout {
        width: root.width
        spacing: Theme.sp3

        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.sp4
            Layout.bottomMargin: 0
            spacing: Theme.sp2

            InfoRow { label: "core"; value: Core.coreVersion }
            InfoRow { label: "data dir"; value: Core.dataDir }
            InfoRow { label: "auth"; value: Core.authLabel }
            InfoRow { label: "relay"; value: Core.relayHost }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.border }

        // ── Known handles ────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.sp4
            Layout.rightMargin: Theme.sp4
            spacing: Theme.sp2

            Text {
                text: "KNOWN HANDLES"
                color: Theme.red
                font.family: Theme.fontHeading
                font.pixelSize: 10
                font.letterSpacing: 10 * Theme.trackEyebrow
            }

            Text {
                visible: handleRepeater.count === 0
                text: "None cached yet."
                color: Theme.fg4
                font.family: Theme.fontBody
                font.pixelSize: 11
            }

            Repeater {
                id: handleRepeater

                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Theme.sp2

                    Text {
                        text: modelData.service
                        color: Theme.fg4
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        Layout.preferredWidth: 60
                    }
                    Text {
                        text: modelData.displayName !== "" ? modelData.displayName
                                                           : modelData.address
                        textFormat: Text.PlainText
                        color: Theme.fg2
                        font.family: Theme.fontBody
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }

        Item { Layout.preferredHeight: Theme.sp2 }
    }
}
