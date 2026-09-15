import QtQuick
import CAV 1.0
import QtQuick.Controls.Basic

TextField {
    id: control

    implicitHeight: 32
    leftPadding: Theme.sp3
    rightPadding: Theme.sp3
    color: Theme.fg1
    placeholderTextColor: Theme.fg4
    selectionColor: Theme.selection
    selectedTextColor: Theme.white
    font.family: Theme.fontBody
    font.pixelSize: 13
    // Qt draws its own focus frame on some styles; the border below is the
    // only focus affordance this design wants.
    focusPolicy: Qt.StrongFocus

    background: Rectangle {
        color: control.enabled ? Theme.bg2 : Theme.bg1
        radius: Theme.radSm
        border.width: 1
        border.color: control.activeFocus ? Theme.red
                    : control.hovered     ? Theme.controlBorder
                                          : Theme.border
        Behavior on border.color { ColorAnimation { duration: 90 } }
    }
}
