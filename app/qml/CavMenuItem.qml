import QtQuick
import CAV 1.0
import QtQuick.Controls.Basic

// A Menu's `delegate` only applies to items it instantiates from a model, not
// to MenuItem children written out by hand, so the styling lives in a real
// component instead.
MenuItem {
    id: control

    implicitHeight: 28
    implicitWidth: 160

    contentItem: Text {
        text: control.text
        color: !control.enabled ? Theme.disabled
             : control.hovered  ? Theme.white
                                : Theme.fg2
        font.family: Theme.fontBody
        font.pixelSize: 12
        verticalAlignment: Text.AlignVCenter
        leftPadding: Theme.sp3
        rightPadding: Theme.sp3
        elide: Text.ElideRight
    }

    background: Rectangle {
        color: control.hovered && control.enabled ? Theme.red10 : "transparent"

        Rectangle {
            width: 2
            height: parent.height
            color: Theme.red
            visible: control.hovered && control.enabled
        }
    }
}
