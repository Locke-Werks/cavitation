import QtQuick
import CAV 1.0
import QtQuick.Controls.Basic
import QtQuick.Layouts

CavDialog {
    id: root

    title: "ABOUT"
    width: 460

    ColumnLayout {
        width: root.width
        spacing: Theme.sp3

        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.sp4
            spacing: Theme.sp2

            RowLayout {
                spacing: Theme.sp2
                Rectangle {
                    Layout.preferredWidth: 12
                    Layout.preferredHeight: 12
                    color: Theme.red
                }
                Text {
                    text: "CAVITATION"
                    color: Theme.fg1
                    font.family: Theme.fontHeading
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    font.letterSpacing: 16 * Theme.trackWider
                }
            }

            Text {
                text: "A native Windows client for the OpenBubbles ecosystem."
                color: Theme.fg3
                font.family: Theme.fontBody
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Text {
                text: "core " + Core.coreVersion + "  ·  Qt " + qtVersion +
                      "  ·  Rust protocol core over cxx"
                color: Theme.fg4
                font.family: Theme.fontMono
                font.pixelSize: 10
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.border }

        Text {
            Layout.fillWidth: true
            Layout.margins: Theme.sp4
            Layout.topMargin: 0
            text: "A fork of OpenBubbles, which builds on BlueBubbles. Both are Apache " +
                  "License 2.0 and the same licence applies here. The protocol work is " +
                  "theirs; see LICENSE and NOTICE. Not endorsed by or affiliated with " +
                  "either project, or with Apple."
            color: Theme.fg4
            font.family: Theme.fontBody
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }
    }
}
