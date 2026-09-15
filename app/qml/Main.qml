import QtQuick
import CAV 1.0
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: window

    width: 1180
    height: 760
    minimumWidth: 720
    minimumHeight: 480
    visible: true
    title: "Cavitation"
    color: Theme.bg0

    // Frameless, with move and resize handed back to the compositor so snap,
    // per-monitor DPI and the shake gesture keep working.
    flags: Qt.Window | Qt.FramelessWindowHint

    property string currentGuid: ""
    property string currentTitle: ""
    property string currentSubtitle: ""
    property string currentService: ""

    // Setup opens itself when there is no usable session, which is the only
    // thing the user can act on at that point.
    Component.onCompleted: if (!Core.ready) setupDialog.open()

    Connections {
        target: Core
        function onToastPosted(text) { toasts.post(text) }
    }

    // ── Shortcuts ────────────────────────────────────────────────
    Shortcut { sequences: ["Ctrl+N"]; onActivated: newChatDialog.open() }
    Shortcut { sequences: ["Ctrl+,"]; onActivated: settingsDialog.open() }
    Shortcut { sequences: ["Ctrl+F"]; onActivated: faceTimeDialog.open() }
    Shortcut { sequences: ["Ctrl+K"]; onActivated: sidebar.focusSearch() }

    // ── Resize edges ─────────────────────────────────────────────
    // A frameless window has no non-client area, so the grab zones are drawn
    // back in. 5px inside the frame, matching what Windows itself uses.
    Repeater {
        model: [
            { e: Qt.TopEdge,                   cur: Qt.SizeVerCursor   },
            { e: Qt.BottomEdge,                cur: Qt.SizeVerCursor   },
            { e: Qt.LeftEdge,                  cur: Qt.SizeHorCursor   },
            { e: Qt.RightEdge,                 cur: Qt.SizeHorCursor   },
            { e: Qt.TopEdge | Qt.LeftEdge,     cur: Qt.SizeFDiagCursor },
            { e: Qt.TopEdge | Qt.RightEdge,    cur: Qt.SizeBDiagCursor },
            { e: Qt.BottomEdge | Qt.LeftEdge,  cur: Qt.SizeBDiagCursor },
            { e: Qt.BottomEdge | Qt.RightEdge, cur: Qt.SizeFDiagCursor }
        ]

        // Not top/bottom/left/right: Item already declares those as FINAL
        // anchor-line properties, and shadowing them fails the whole document
        // at load with "Cannot override FINAL property".
        delegate: Item {
            required property var modelData
            readonly property int edges: modelData.e
            readonly property bool atTop: edges & Qt.TopEdge
            readonly property bool atBottom: edges & Qt.BottomEdge
            readonly property bool atLeft: edges & Qt.LeftEdge
            readonly property bool atRight: edges & Qt.RightEdge
            readonly property int grab: 5

            z: 9999
            visible: window.visibility !== Window.Maximized

            x: atLeft ? 0 : (atRight ? window.width - grab : grab)
            y: atTop ? 0 : (atBottom ? window.height - grab : grab)
            width: (atLeft || atRight) ? grab : window.width - grab * 2
            height: (atTop || atBottom) ? grab : window.height - grab * 2

            MouseArea {
                anchors.fill: parent
                cursorShape: modelData.cur
                onPressed: window.startSystemResize(parent.edges)
            }
        }
    }

    // ── Layout ───────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            Layout.fillWidth: true
            authLabel: Core.authLabel
            authReady: Core.ready
            statusLine: Core.statusLine
            onMenuRequested: appMenu.popup()
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Sidebar {
                id: sidebar
                Layout.preferredWidth: Theme.sidebarWidth
                Layout.fillHeight: true
                onNewChatRequested: newChatDialog.open()
                onCurrentGuidChanged: window.syncSelection()
            }

            ConversationPane {
                Layout.fillWidth: true
                Layout.fillHeight: true
                chatGuid: window.currentGuid
                chatTitle: window.currentTitle
                chatSubtitle: window.currentSubtitle
                chatService: window.currentService
                onFaceTimeRequested: faceTimeDialog.open()
            }
        }
    }

    // The sidebar owns the selected guid; the header text comes from the same
    // model row so the two cannot disagree.
    function syncSelection() {
        currentGuid = sidebar.currentGuid
        const chat = ChatList.chatByGuid(currentGuid)
        currentTitle = chat.title !== undefined ? chat.title : ""
        currentSubtitle = chat.participantSummary !== undefined ? chat.participantSummary : ""
        currentService = chat.service !== undefined ? chat.service : ""
    }

    // ── App menu ─────────────────────────────────────────────────
    CavMenu {
        id: appMenu
        x: Theme.sp3
        y: Theme.titleBarHeight
        implicitWidth: 200

        CavMenuItem { text: "New conversation\tCtrl+N"; onTriggered: newChatDialog.open() }
        CavMenuItem { text: "FaceTime…\tCtrl+F";   onTriggered: faceTimeDialog.open() }
        CavSeparator {}
        CavMenuItem { text: "Setup";                    onTriggered: setupDialog.open() }
        CavMenuItem { text: "Settings\tCtrl+,";         onTriggered: settingsDialog.open() }
        CavSeparator {}
        CavMenuItem { text: "About";                    onTriggered: aboutDialog.open() }
        CavMenuItem { text: "Quit";                     onTriggered: window.close() }
    }

    // ── Dialogs ──────────────────────────────────────────────────
    SetupDialog    { id: setupDialog }
    SettingsDialog { id: settingsDialog }
    AboutDialog    { id: aboutDialog }
    FaceTimeDialog { id: faceTimeDialog }
    NewChatDialog {
        id: newChatDialog
        onNotImplemented: function(message) { toasts.post(message) }
    }

    ToastLayer {
        id: toasts
        anchors.fill: parent
        z: 1000
    }
}
