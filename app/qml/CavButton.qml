import QtQuick
import CAV 1.0
import QtQuick.Controls.Basic

Button {
    id: control

    // A primary button carries the red; everything else is a hairline box that
    // only picks up red on hover. One red thing per surface.
    property bool primary: false
    property bool danger: false

    readonly property color accent: danger ? Theme.focusRing : Theme.red

    implicitHeight: 30
    padding: Theme.sp3
    font.family: Theme.fontHeading
    font.pixelSize: 12
    font.weight: Font.Medium
    font.letterSpacing: 12 * Theme.trackHeading

    contentItem: Text {
        text: control.text
        font: control.font
        color: !control.enabled ? Theme.disabled
             : control.primary  ? Theme.white
             : control.hovered  ? Theme.white
                                : Theme.fg2
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: Theme.radSm
        color: {
            if (!control.enabled) return "transparent"
            if (control.down) return control.primary ? Qt.darker(control.accent, 2.2)
                                                     : Theme.red10
            if (control.hovered) return control.primary ? Qt.darker(control.accent, 2.6)
                                                        : Theme.red05
            return control.primary ? Theme.primaryBg : "transparent"
        }
        border.width: 1
        border.color: {
            if (!control.enabled) return Theme.border
            if (control.primary) return control.accent
            return control.hovered ? control.accent : Theme.controlBorder
        }

        Behavior on color { ColorAnimation { duration: 90 } }
        Behavior on border.color { ColorAnimation { duration: 90 } }
    }
}
