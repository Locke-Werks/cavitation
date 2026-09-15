import QtQuick
import CAV 1.0
import QtQuick.Controls.Basic

Menu {
    id: control

    implicitWidth: 170
    padding: Theme.sp1

    background: Rectangle {
        implicitWidth: control.implicitWidth
        color: Theme.bg1
        radius: Theme.radSm
        border.width: 1
        border.color: Theme.border
    }
}
