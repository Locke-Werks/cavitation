import QtQuick
import CAV 1.0
import QtQuick.Controls.Basic

// Minimise / maximise / close. Its own file rather than an inline component
// because inline components have to be declared at the top level of a
// document, and this one is used from inside a nested Row.
Button {
    id: control

    property bool closeButton: false

    implicitWidth: 44
    implicitHeight: Theme.titleBarHeight
    flat: true

    contentItem: Text {
        text: control.text
        // Segoe Fluent Icons ships with Windows 11 and carries the real
        // caption glyphs; the bundled brand fonts do not.
        font.family: "Segoe Fluent Icons"
        font.pixelSize: 10
        color: control.hovered ? Theme.white : Theme.fg3
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        color: !control.hovered   ? "transparent"
             : control.closeButton ? Theme.red
                                   : Theme.controlHover
    }
}
