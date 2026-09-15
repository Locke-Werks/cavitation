import QtQuick
import CAV 1.0
import QtQuick.Controls.Basic
import QtQuick.Layouts

CavDialog {
    id: root

    title: "FACETIME"
    width: 440

    property string lastLink: ""

    onOpened: lastLink = ""

    ColumnLayout {
        width: root.width
        spacing: Theme.sp2

        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.sp4
            spacing: Theme.sp2

            Text {
                text: "Call (Apple ID or phone number)"
                color: Theme.fg3
                font.family: Theme.fontBody
                font.pixelSize: 11
            }

            CavTextField {
                id: target
                Layout.fillWidth: true
                placeholderText: "+15555550123 or someone@icloud.com"
                onAccepted: startButton.clicked()
            }

            CavButton {
                id: startButton
                text: "START CALL"
                primary: true
                implicitWidth: 120
                enabled: target.text.trim() !== ""
                onClicked: root.lastLink = Core.startFaceTimeCall(target.text.trim())
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Theme.sp2
                visible: root.lastLink !== ""
                implicitHeight: linkText.implicitHeight + Theme.sp3 * 2
                color: Theme.bg2
                radius: Theme.radSm
                border.width: 1
                border.color: Theme.border

                TextEdit {
                    id: linkText
                    anchors.fill: parent
                    anchors.margins: Theme.sp3
                    text: root.lastLink
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.WrapAnywhere
                    color: Theme.linkColor
                    selectionColor: Theme.selection
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                }
            }
        }
    }
}
