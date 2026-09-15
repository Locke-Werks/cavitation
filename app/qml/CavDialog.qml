import QtQuick
import CAV 1.0
import QtQuick.Controls.Basic
import QtQuick.Layouts

// Shared modal frame. Everything inside is laid out by the caller; this only
// owns the surface, the border, the title strip and the close affordance.
Popup {
    id: root

    property string title: ""
    property string subtitle: ""
    default property alias content: body.data

    anchors.centerIn: Overlay.overlay
    modal: true
    focus: true
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120 }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 100 }
    }

    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.72)
    }

    background: Rectangle {
        color: Theme.bg1
        radius: Theme.radSm
        border.width: 1
        border.color: Theme.border
    }

    ColumnLayout {
        spacing: 0

        // ── Title strip ──────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 44
            color: Theme.bg0
            radius: Theme.radSm

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.sp4
                anchors.rightMargin: Theme.sp2
                spacing: Theme.sp3

                Rectangle {
                    Layout.preferredWidth: 2
                    Layout.preferredHeight: 14
                    color: Theme.red
                }

                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true

                    Text {
                        text: root.title
                        color: Theme.fg1
                        font.family: Theme.fontHeading
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        font.letterSpacing: 13 * Theme.trackHeading
                    }
                    Text {
                        text: root.subtitle
                        visible: root.subtitle !== ""
                        color: Theme.fg4
                        font.family: Theme.fontBody
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                CavButton {
                    // Fluent Icons, not the brand fonts: Chakra Petch has no
                    // close glyph and renders it as a missing-character box.
                    text: ""
                    font.family: "Segoe Fluent Icons"
                    font.pixelSize: 9
                    implicitWidth: 30
                    implicitHeight: 24
                    danger: true
                    onClicked: root.close()
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.border
            }
        }

        // ── Caller content ───────────────────────────────────────
        Item {
            id: body
            Layout.fillWidth: true
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
}
