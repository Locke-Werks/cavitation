import QtQuick
import CAV 1.0
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    id: root

    property alias currentGuid: internal.currentGuid
    signal newChatRequested()

    function focusSearch() {
        search.forceActiveFocus()
        search.selectAll()
    }

    color: Theme.bg1

    QtObject {
        id: internal
        property string currentGuid: ""
    }

    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: Theme.border
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Search + new ─────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 48
            color: Theme.bg1

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.sp3
                spacing: Theme.sp2

                CavTextField {
                    id: search
                    Layout.fillWidth: true
                    placeholderText: "Search conversations"
                    onTextChanged: ChatList.filter = text
                }

                CavButton {
                    text: "NEW"
                    primary: true
                    // Letter-spaced heading type needs more room than the
                    // glyph count suggests; 52 clipped it to "NE...".
                    implicitWidth: 64
                    onClicked: root.newChatRequested()
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.border
            }
        }

        // ── Conversations ────────────────────────────────────────
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: ChatList
            currentIndex: -1
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: CavScrollBar {}

            delegate: ChatRow {
                selected: guid === internal.currentGuid
                onClicked: {
                    internal.currentGuid = guid
                    Core.markChatRead(guid)
                }
                onPinToggled: Core.pinChat(guid, !isPinned, 0)
                onArchiveToggled: Core.archiveChat(guid, !isArchived)
                onMarkReadRequested: Core.markChatRead(guid)
            }

            // Empty states are distinct: nothing at all versus nothing that
            // matches what was typed. Saying "no conversations" over a search
            // that simply missed is the kind of thing that makes an app feel
            // broken.
            Item {
                anchors.fill: parent
                visible: list.count === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width - Theme.sp8
                    spacing: Theme.sp2

                    Text {
                        text: search.text.length > 0 ? "NO MATCHES" : "NO CONVERSATIONS"
                        color: Theme.fg4
                        font.family: Theme.fontHeading
                        font.pixelSize: 11
                        font.letterSpacing: 11 * Theme.trackEyebrow
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: search.text.length > 0
                              ? "Nothing here matches \"" + search.text + "\"."
                              : "Start one with NEW, or sign in from Setup."
                        color: Theme.fg4
                        font.family: Theme.fontBody
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }
        }

        // ── Archived toggle ──────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 32
            color: Theme.bg0

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.border
            }

            CheckBox {
                id: archivedToggle
                anchors.left: parent.left
                anchors.leftMargin: Theme.sp3
                anchors.verticalCenter: parent.verticalCenter
                checked: ChatList.includeArchived
                onToggled: ChatList.includeArchived = checked

                indicator: Rectangle {
                    implicitWidth: 12
                    implicitHeight: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: archivedToggle.checked ? Theme.red : "transparent"
                    border.width: 1
                    border.color: archivedToggle.checked ? Theme.red : Theme.controlBorder
                    radius: Theme.radSm
                }

                contentItem: Text {
                    text: "Show archived"
                    color: Theme.fg3
                    font.family: Theme.fontBody
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: archivedToggle.indicator.width + Theme.sp2
                }
            }
        }
    }
}
