import QtQuick
import CAV 1.0
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Window

// Frameless title bar. Dragging and edge-resizing are handed back to the
// compositor through startSystemMove/startSystemResize rather than being
// reimplemented, so Aero snap, multi-monitor DPI and the shake gesture all
// keep working.
Rectangle {
    id: root

    property string statusLine: ""
    property string authLabel: ""
    property bool authReady: false

    signal menuRequested()

    implicitHeight: Theme.titleBarHeight
    color: Theme.bg0

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.border
    }

    DragHandler {
        target: null
        grabPermissions: PointerHandler.CanTakeOverFromAnything
        onActiveChanged: if (active) root.Window.window.startSystemMove()
    }

    TapHandler {
        gesturePolicy: TapHandler.DragThreshold
        onDoubleTapped: root.Window.window.visibility === Window.Maximized
                        ? root.Window.window.showNormal()
                        : root.Window.window.showMaximized()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.sp3
        spacing: Theme.sp3

        // ── Mark, doubling as the app menu ───────────────────────
        Rectangle {
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            color: markHover.hovered ? Theme.red10 : "transparent"
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 10
                color: Theme.red
            }

            HoverHandler { id: markHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.menuRequested() }

            ToolTip.visible: markHover.hovered
            ToolTip.text: "Menu"
            ToolTip.delay: 600
        }

        Text {
            text: "CAVITATION"
            color: Theme.fg1
            font.family: Theme.fontHeading
            font.pixelSize: 12
            font.weight: Font.Bold
            font.letterSpacing: 12 * Theme.trackEyebrow
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 14
            color: Theme.border
        }

        // ── Auth state ───────────────────────────────────────────
        Rectangle {
            Layout.preferredWidth: 6
            Layout.preferredHeight: 6
            radius: Theme.radFull
            color: root.authReady ? Theme.success : Theme.warning
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.authLabel
            color: Theme.fg3
            font.family: Theme.fontMono
            font.pixelSize: 11
        }

        // ── Status ───────────────────────────────────────────────
        Text {
            text: root.statusLine
            color: Theme.fg4
            font.family: Theme.fontBody
            font.pixelSize: 11
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        // ── Window controls ──
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            CavCaptionButton {
                text: ""
                onClicked: root.Window.window.showMinimized()
            }
            CavCaptionButton {
                text: root.Window.window.visibility === Window.Maximized
                      ? "" : ""
                onClicked: root.Window.window.visibility === Window.Maximized
                           ? root.Window.window.showNormal()
                           : root.Window.window.showMaximized()
            }
            CavCaptionButton {
                text: ""
                closeButton: true
                onClicked: root.Window.window.close()
            }
        }
    }
}
