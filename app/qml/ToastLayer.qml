import QtQuick
import CAV 1.0
import QtQuick.Controls.Basic
import QtQuick.Layouts

// Transient messages, newest at the bottom. Errors from the core land here
// rather than in a modal, because most of them are things the user can neither
// fix nor usefully acknowledge mid-conversation.
Item {
    id: root

    property int maxVisible: 4
    property int lifetimeMs: 6000

    // Removal is by serial, never by row index: a toast that expires while an
    // older one is still on screen would otherwise take whichever row happens
    // to sit at its remembered index.
    property int nextSerial: 0

    function post(text) {
        toasts.append({ serial: root.nextSerial++, body: text })
        while (toasts.count > root.maxVisible) toasts.remove(0)
    }

    function dismiss(serial) {
        for (let i = 0; i < toasts.count; ++i) {
            if (toasts.get(i).serial === serial) {
                toasts.remove(i)
                return
            }
        }
    }

    ListModel { id: toasts }

    ColumnLayout {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.sp4
        width: Math.min(380, root.width - Theme.sp8)
        spacing: Theme.sp2

        Repeater {
            model: toasts

            delegate: Rectangle {
                id: toast

                required property int serial
                required property string body

                Layout.fillWidth: true
                implicitHeight: toastText.implicitHeight + Theme.sp3 * 2
                color: Theme.bg2
                radius: Theme.radSm
                border.width: 1
                border.color: Theme.border

                Rectangle {
                    width: 2
                    height: parent.height
                    color: Theme.red
                }

                Text {
                    id: toastText
                    anchors.fill: parent
                    anchors.margins: Theme.sp3
                    anchors.leftMargin: Theme.sp4
                    text: toast.body
                    // Error text can carry message or database content.
                    textFormat: Text.PlainText
                    color: Theme.fg2
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignVCenter
                }

                // Hover holds a toast open so a long error can be read, but
                // there is deliberately no TapHandler: the stack sits over the
                // composer, and a tap handler here ate the click on ATTACH
                // instead of dismissing and passing it through. A plain
                // Rectangle accepts no mouse events, so clicks fall through to
                // the buttons underneath and the timer does the dismissing.
                HoverHandler { id: toastHover }

                // A value source, so opacity is not also given a plain binding
                // above; the two cannot coexist on one property.
                NumberAnimation on opacity {
                    from: 0
                    to: 1
                    duration: 140
                    running: true
                }

                Timer {
                    interval: root.lifetimeMs
                    // Hovering holds it open, so a long error can be read
                    // before it goes.
                    running: !toastHover.hovered
                    onTriggered: root.dismiss(toast.serial)
                }
            }
        }
    }
}
