import QtQuick
import CAV 1.0
import QtQuick.Controls.Basic

// Thin, unobtrusive, and it does not reserve a gutter. The Basic style is
// forced in main.cpp precisely so these overrides apply; the Windows native
// styles ignore contentItem/background on ScrollBar.
ScrollBar {
    id: control

    implicitWidth: 10
    padding: 2
    policy: ScrollBar.AsNeeded

    contentItem: Rectangle {
        implicitWidth: 6
        radius: Theme.radSm
        color: control.pressed ? Theme.red
             : control.hovered ? Qt.darker(Theme.red, 1.4)
                               : Theme.controlHover
        opacity: control.policy === ScrollBar.AlwaysOn || control.active ? 1 : 0

        Behavior on color { ColorAnimation { duration: 90 } }
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    background: Rectangle {
        color: "transparent"
    }
}
