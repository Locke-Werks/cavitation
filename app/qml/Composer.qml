import QtQuick
import CAV 1.0
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    id: root

    property string chatGuid: ""
    // Set to a message guid to turn the composer into an edit box for it.
    property string editingGuid: ""

    signal sent(string text)
    signal edited(string messageGuid, string text)
    signal attachRequested(string text)

    implicitHeight: layout.implicitHeight + Theme.sp3 * 2
    color: Theme.bg1

    function focusInput() { input.forceActiveFocus() }

    function beginEdit(messageGuid, currentText) {
        editingGuid = messageGuid
        input.text = currentText
        input.forceActiveFocus()
        input.cursorPosition = input.length
    }

    function cancelEdit() {
        editingGuid = ""
        input.clear()
    }

    function submit() {
        const body = input.text.trim()
        if (body === "") return
        if (editingGuid !== "") {
            root.edited(editingGuid, body)
            root.cancelEdit()
        } else {
            root.sent(body)
            input.clear()
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.border
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Theme.sp3
        spacing: Theme.sp2

        // ── Edit banner ──────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            visible: root.editingGuid !== ""
            spacing: Theme.sp2

            Rectangle {
                Layout.preferredWidth: 2
                Layout.preferredHeight: 14
                color: Theme.red
            }

            Text {
                text: "Editing message"
                color: Theme.fg3
                font.family: Theme.fontHeading
                font.pixelSize: 10
                font.letterSpacing: 10 * Theme.trackEyebrow
                Layout.fillWidth: true
            }

            CavButton {
                text: "CANCEL"
                implicitWidth: 64
                implicitHeight: 22
                onClicked: root.cancelEdit()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.sp2

            Rectangle {
                Layout.fillWidth: true
                // Grows with the draft up to a ceiling, then scrolls, so a
                // long message is visible while composing without the input
                // eating the transcript.
                implicitHeight: Math.min(Math.max(Theme.composerMinH,
                                                  input.implicitHeight + Theme.sp2 * 2), 160)
                color: Theme.bg2
                radius: Theme.radSm
                border.width: 1
                border.color: input.activeFocus ? Theme.red : Theme.border

                Behavior on border.color { ColorAnimation { duration: 90 } }

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: Theme.sp2
                    clip: true
                    ScrollBar.vertical: CavScrollBar {}

                    TextArea {
                        id: input
                        placeholderText: root.editingGuid !== ""
                                         ? "Edit and press Enter"
                                         : "Message. Enter sends, Shift+Enter for a new line"
                        color: Theme.fg1
                        placeholderTextColor: Theme.fg4
                        selectionColor: Theme.selection
                        selectedTextColor: Theme.white
                        font.family: Theme.fontBody
                        font.pixelSize: 13
                        wrapMode: TextArea.Wrap
                        background: null
                        enabled: root.chatGuid !== ""

                        Keys.onPressed: function(event) {
                            if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter)
                                return
                            if (event.modifiers & Qt.ShiftModifier)
                                return          // fall through, insert a newline
                            root.submit()
                            event.accepted = true
                        }

                        Keys.onEscapePressed: function(event) {
                            if (root.editingGuid !== "") {
                                root.cancelEdit()
                                event.accepted = true
                            }
                        }
                    }
                }
            }

            CavButton {
                text: "ATTACH"
                implicitWidth: 72
                enabled: root.chatGuid !== "" && root.editingGuid === ""
                Layout.alignment: Qt.AlignBottom
                onClicked: root.attachRequested(input.text.trim())
            }

            CavButton {
                text: root.editingGuid !== "" ? "SAVE" : "SEND"
                primary: true
                implicitWidth: 72
                enabled: root.chatGuid !== "" && input.text.trim() !== ""
                Layout.alignment: Qt.AlignBottom
                onClicked: root.submit()
            }
        }
    }
}
