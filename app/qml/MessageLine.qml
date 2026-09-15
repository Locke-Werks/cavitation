import QtQuick
import CAV 1.0
import QtQuick.Controls.Basic
import QtQuick.Layouts

// One transcript line, IRC style: time, nick, text. Wrapped text hangs under
// the message column instead of returning to the left edge, which is what
// keeps a dense log scannable.
Item {
    id: root

    required property int index
    required property string guid
    required property string senderDisplayName
    required property string text
    required property string richText
    required property bool isFromMe
    required property string clockLabel
    required property string fullTimeLabel
    required property bool isUnsent
    required property bool isEdited
    required property var attachments
    required property bool isRunStart
    required property bool showDaySeparator
    required property string dayLabel

    signal reactRequested(string reaction)
    signal editRequested(string currentText)
    signal unsendRequested()

    width: ListView.view ? ListView.view.width : implicitWidth
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 0

        // ── Day separator ────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.topMargin: root.showDaySeparator ? Theme.sp4 : 0
            Layout.bottomMargin: root.showDaySeparator ? Theme.sp2 : 0
            implicitHeight: root.showDaySeparator ? 14 : 0
            visible: root.showDaySeparator

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.sp3
                anchors.rightMargin: Theme.sp3
                height: 1
                color: Theme.borderSoft
            }

            Rectangle {
                anchors.centerIn: parent
                width: dayText.implicitWidth + Theme.sp4
                height: parent.height
                color: Theme.bg0

                Text {
                    id: dayText
                    anchors.centerIn: parent
                    text: root.dayLabel
                    color: Theme.fg4
                    font.family: Theme.fontHeading
                    font.pixelSize: 10
                    font.letterSpacing: 10 * Theme.trackEyebrow
                }
            }
        }

        // ── The line ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: line.implicitHeight + Theme.lineGapV * 2
            color: lineHover.hovered ? Theme.rowHover : "transparent"

            // Extra breathing room where the speaker changes, so a run from
            // one person reads as a block without needing a rule between them.
            Layout.topMargin: root.isRunStart && !root.showDaySeparator
                              ? Theme.speakerGapV - Theme.lineGapV : 0

            HoverHandler { id: lineHover }

            RowLayout {
                id: line
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: Theme.sp3
                anchors.rightMargin: Theme.sp3
                anchors.topMargin: Theme.lineGapV
                spacing: Theme.sp2

                // Timestamp
                Text {
                    Layout.preferredWidth: Theme.tsColumnWidth
                    Layout.alignment: Qt.AlignTop
                    text: root.clockLabel
                    color: Theme.fg4
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignLeft

                    ToolTip.visible: tsHover.hovered
                    ToolTip.text: root.fullTimeLabel
                    ToolTip.delay: 500
                    HoverHandler { id: tsHover }
                }

                // Nick, right-aligned against the message column so the text
                // all starts on one line regardless of name length.
                Text {
                    Layout.preferredWidth: Theme.nickColumnWidth
                    Layout.alignment: Qt.AlignTop
                    text: "<" + (root.senderDisplayName === "" ? "me" : root.senderDisplayName) + ">"
                    // A nick is remote input, and the angle brackets around
                    // it look exactly like a tag to AutoText.
                    textFormat: Text.PlainText
                    color: Theme.nickColor(root.senderDisplayName, root.isFromMe)
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    font.weight: root.isFromMe ? Font.DemiBold : Font.Normal
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }

                // Message column
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: Theme.sp1

                    // RichText, but the HTML is built in text_links.cpp from
                    // fully escaped input, so the only markup that reaches the
                    // renderer is <a> and <br>. TextEdit rather than Text so
                    // the transcript can actually be selected and copied.
                    TextEdit {
                        id: body
                        Layout.fillWidth: true
                        visible: root.text !== "" && !root.isUnsent
                        text: root.richText
                        textFormat: TextEdit.RichText
                        readOnly: true
                        selectByMouse: true
                        wrapMode: TextEdit.Wrap
                        color: Theme.fg2
                        selectionColor: Theme.selection
                        selectedTextColor: Theme.white
                        font.family: Theme.fontBody
                        font.pixelSize: 13

                        onLinkActivated: function(link) { Qt.openUrlExternally(link) }

                        // Links only; the I-beam stays everywhere else so the
                        // text still reads as selectable.
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton
                            cursorShape: body.hoveredLink !== "" ? Qt.PointingHandCursor
                                                                 : Qt.IBeamCursor
                        }
                    }

                    Text {
                        visible: root.isUnsent
                        text: "message unsent"
                        color: Theme.systemColor
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        font.italic: true
                    }

                    Text {
                        visible: root.isEdited && !root.isUnsent
                        text: "(edited)"
                        color: Theme.fg4
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                    }

                    // ── Attachments, indented under the message ──
                    Repeater {
                        model: root.isUnsent ? [] : root.attachments

                        delegate: Loader {
                            required property var modelData
                            Layout.fillWidth: true
                            sourceComponent: modelData.isImage ? imageAttachment : fileAttachment

                            Component {
                                id: imageAttachment

                                Item {
                                    implicitHeight: thumb.paintedHeight
                                    implicitWidth: thumb.paintedWidth

                                    Image {
                                        id: thumb
                                        source: "file:///" + modelData.localPath
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                        // Inline previews are capped rather
                                        // than filling the pane: a tall photo
                                        // at full width pushes the rest of the
                                        // transcript off screen.
                                        width: Math.min(implicitWidth, 420)
                                        height: Math.min(implicitHeight, 320)
                                        // Caps decode memory; a full-res photo
                                        // decoded at native size per line is
                                        // how a chat window reaches a gigabyte.
                                        sourceSize.width: 840
                                        mipmap: true

                                        TapHandler {
                                            onDoubleTapped: Core.openAttachment(modelData.localPath)
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            color: "transparent"
                                            border.width: 1
                                            border.color: imgHover.hovered ? Theme.red : Theme.border
                                        }

                                        HoverHandler { id: imgHover }

                                        ToolTip.visible: imgHover.hovered
                                        ToolTip.text: modelData.filename + "  ·  double-click to open"
                                        ToolTip.delay: 500
                                    }
                                }
                            }

                            Component {
                                id: fileAttachment

                                Row {
                                    spacing: Theme.sp2

                                    Text {
                                        text: "▶ " + modelData.filename
                                        textFormat: Text.PlainText
                                        color: Theme.linkColor
                                        font.family: Theme.fontMono
                                        font.pixelSize: 12
                                        font.underline: fileHover.hovered

                                        HoverHandler {
                                            id: fileHover
                                            cursorShape: Qt.PointingHandCursor
                                        }
                                        TapHandler {
                                            onTapped: Core.openAttachment(modelData.localPath)
                                        }
                                    }

                                    Text {
                                        text: modelData.sizeLabel + "  ·  " + modelData.mimeType
                                        color: Theme.fg4
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }

            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: lineMenu.popup()
            }

            CavMenu {
                id: lineMenu

                CavMenuItem { text: "React ♥";       onTriggered: root.reactRequested("love") }
                CavMenuItem { text: "React 👍"; onTriggered: root.reactRequested("like") }
                CavMenuItem { text: "React 👎"; onTriggered: root.reactRequested("dislike") }
                CavSeparator {}
                CavMenuItem {
                    text: "Copy"
                    onTriggered: { body.selectAll(); body.copy(); body.deselect() }
                }
                CavMenuItem {
                    text: "Edit…"
                    enabled: root.isFromMe && !root.isUnsent
                    onTriggered: root.editRequested(root.text)
                }
                CavMenuItem {
                    text: "Unsend"
                    enabled: root.isFromMe && !root.isUnsent
                    onTriggered: root.unsendRequested()
                }
            }
        }
    }
}
