import QtQuick
import CAV 1.0
import QtQuick.Controls.Basic
import QtQuick.Layouts

ItemDelegate {
    id: row

    required property int index
    required property string guid
    required property string title
    required property string subtitle
    required property string service
    required property bool isPinned
    required property bool isArchived
    required property int unreadCount
    required property string timeLabel

    property bool selected: false

    signal pinToggled()
    signal archiveToggled()
    signal markReadRequested()

    width: ListView.view ? ListView.view.width : implicitWidth
    height: Theme.chatRowHeight
    padding: 0

    background: Rectangle {
        color: row.selected ? Theme.bg2
             : row.hovered  ? Theme.red02
                            : "transparent"

        // Selection reads as a red edge rather than a red fill, so a selected
        // row does not compete with the unread badge next to it.
        Rectangle {
            width: 2
            height: parent.height
            color: Theme.red
            visible: row.selected
        }

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Theme.borderSoft
        }

        Behavior on color { ColorAnimation { duration: 90 } }
    }

    leftPadding: Theme.sp4
    rightPadding: Theme.sp3
    topPadding: Theme.sp2
    bottomPadding: Theme.sp2

    // No anchors.fill here: a Control already sizes and positions its
    // contentItem from its padding, and anchoring on top of that fights it.
    // That fight is what squeezed the right-hand column until "21:19" clipped
    // to "21".
    contentItem: RowLayout {
        spacing: Theme.sp2

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.sp1

                Text {
                    text: "◆"
                    visible: row.isPinned
                    color: Theme.red
                    font.pixelSize: 8
                }

                Text {
                    text: Theme.serviceLabel(row.service)
                    color: Theme.serviceColor(row.service)
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                }

                Text {
                    text: row.title
                    // A chat title is remote input. Text defaults to AutoText,
                    // which sniffs for markup and renders it, so a contact
                    // named "<b>x</b>" would style the list.
                    textFormat: Text.PlainText
                    color: row.unreadCount > 0 ? Theme.white : Theme.fg2
                    font.family: Theme.fontBody
                    font.pixelSize: 13
                    font.weight: row.unreadCount > 0 ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Text {
                text: row.subtitle
                // Same again, and this one is the message body: AutoText was
                // rendering "<b>not bold</b>" from a message as actual bold.
                textFormat: Text.PlainText
                color: Theme.fg4
                font.family: Theme.fontBody
                font.pixelSize: 11
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.fillWidth: true
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            // Without a floor the fillWidth title column takes everything and
            // squeezes this one, which clipped "21:19" down to "21".
            Layout.minimumWidth: timestamp.implicitWidth
            spacing: Theme.sp1

            Text {
                id: timestamp
                text: row.timeLabel
                color: Theme.fg4
                font.family: Theme.fontMono
                font.pixelSize: 10
                Layout.preferredWidth: implicitWidth
                Layout.alignment: Qt.AlignRight
            }

            Rectangle {
                visible: row.unreadCount > 0
                Layout.alignment: Qt.AlignRight
                implicitWidth: Math.max(16, badge.implicitWidth + Theme.sp2)
                implicitHeight: 16
                color: Theme.red
                radius: Theme.radSm

                Text {
                    id: badge
                    anchors.centerIn: parent
                    text: row.unreadCount > 99 ? "99+" : row.unreadCount
                    color: Theme.white
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: contextMenu.popup()
    }

    CavMenu {
        id: contextMenu

        CavMenuItem {
            text: row.isPinned ? "Unpin" : "Pin"
            onTriggered: row.pinToggled()
        }
        CavMenuItem {
            text: row.isArchived ? "Unarchive" : "Archive"
            onTriggered: row.archiveToggled()
        }
        CavMenuItem {
            text: "Mark read"
            onTriggered: row.markReadRequested()
        }
    }
}
