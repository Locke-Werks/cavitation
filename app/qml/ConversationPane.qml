import QtQuick
import CAV 1.0
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    id: root

    property string chatGuid: ""
    property string chatTitle: ""
    property string chatSubtitle: ""
    property string chatService: ""

    signal faceTimeRequested()

    color: Theme.bg0

    onChatGuidChanged: MessageModel.chatGuid = chatGuid

    // ── Empty state ──────────────────────────────────────────────
    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.sp8, 360)
        spacing: Theme.sp3
        visible: root.chatGuid === ""

        Text {
            text: "NO CHANNEL SELECTED"
            color: Theme.fg4
            font.family: Theme.fontHeading
            font.pixelSize: 12
            font.letterSpacing: 12 * Theme.trackEyebrow
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: "Pick a conversation on the left, or start one with NEW."
            color: Theme.fg4
            font.family: Theme.fontBody
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        visible: root.chatGuid !== ""

        // ── Channel header ───────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 44
            color: Theme.bg1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.sp4
                anchors.rightMargin: Theme.sp3
                spacing: Theme.sp3

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: root.chatTitle
                        textFormat: Text.PlainText
                        color: Theme.fg1
                        font.family: Theme.fontHeading
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        font.letterSpacing: 13 * Theme.trackHeading
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: Theme.sp2
                        Layout.fillWidth: true

                        // The transport decides what actually works in this
                        // thread, so it belongs in the header rather than only
                        // on the list row.
                        Text {
                            text: Theme.serviceLabel(root.chatService)
                            visible: root.chatService !== ""
                            color: Theme.serviceColor(root.chatService)
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.chatSubtitle
                            textFormat: Text.PlainText
                            visible: root.chatSubtitle !== ""
                            color: Theme.fg4
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                CavButton {
                    text: "FACETIME"
                    // Letter-spaced heading type is wider than the glyph count
                    // implies; 84 clipped this to "FACETI...".
                    implicitWidth: 112
                    onClicked: root.faceTimeRequested()
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.border
            }
        }

        // ── Transcript ───────────────────────────────────────────
        ListView {
            id: transcript
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: MessageModel
            spacing: 0
            boundsBehavior: Flickable.StopAtBounds
            // Rows vary a lot in height once images are in the mix, so let the
            // view measure what it shows rather than guessing an average.
            cacheBuffer: 800

            ScrollBar.vertical: CavScrollBar {}

            delegate: MessageLine {
                onReactRequested: function(reaction) { Core.tapback(guid, reaction) }
                onEditRequested: function(currentText) { composer.beginEdit(guid, currentText) }
                onUnsendRequested: Core.unsendMessage(guid)
            }

            // Following the tail is conditional: yanking someone back to the
            // bottom while they are reading history is the single most
            // irritating thing a chat window does.
            property bool atTail: true
            onContentYChanged: atTail = (contentHeight - contentY - height) < 48

            Connections {
                target: MessageModel
                function onAppended(firstRow, count) {
                    if (transcript.atTail) Qt.callLater(transcript.positionViewAtEnd)
                }
                function onChatGuidChanged() {
                    transcript.atTail = true
                    Qt.callLater(transcript.positionViewAtEnd)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: transcript.count === 0
                text: "No messages yet."
                color: Theme.fg4
                font.family: Theme.fontMono
                font.pixelSize: 12
            }

            // Jump-to-latest, shown only when it would do something.
            CavButton {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Theme.sp4
                text: "JUMP TO LATEST"
                implicitWidth: 128
                visible: !transcript.atTail && transcript.count > 0
                onClicked: {
                    transcript.atTail = true
                    transcript.positionViewAtEnd()
                }
            }
        }

        // ── Composer ─────────────────────────────────────────────
        Composer {
            id: composer
            Layout.fillWidth: true
            chatGuid: root.chatGuid

            onSent: function(text) {
                Core.sendMessage(root.chatGuid, text)
                transcript.atTail = true
            }
            onEdited: function(messageGuid, text) { Core.editMessage(messageGuid, text) }
            onAttachRequested: function(text) {
                const path = Core.pickFile()
                if (path !== "") Core.attachFile(root.chatGuid, text, path)
            }
        }
    }
}
