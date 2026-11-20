import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Components
import qs.Services

// Full-screen overlay with lock / suspend / log out / reboot / shut down.
// Keys: the letter on each button runs it; Esc cancels a countdown or closes.
PanelWindow {
    id: root

    screen: Panels.sessionScreen

    WlrLayershell.namespace: "vesper-session"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: Qt.alpha("black", 0.5)

    // Action waiting for its countdown, and seconds left.
    property string pendingId: ""
    property int remaining: 0

    function trigger(action) {
        const countdown = Math.max(0, Settings.session.countdown || 0);
        if (!action.confirm || countdown === 0 || pendingId === action.id) {
            runNow(action.id);
            return;
        }
        pendingId = action.id;
        remaining = countdown;
        countdownTimer.restart();
    }

    function runNow(id) {
        countdownTimer.stop();
        pendingId = "";
        Panels.closeSession();
        SessionService.run(id);
    }

    function cancelOrClose() {
        if (pendingId !== "") {
            countdownTimer.stop();
            pendingId = "";
        } else {
            Panels.closeSession();
        }
    }

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        onTriggered: {
            root.remaining--;
            if (root.remaining <= 0)
                root.runNow(root.pendingId);
        }
    }

    // Click outside the buttons closes.
    MouseArea {
        anchors.fill: parent
        onClicked: root.cancelOrClose()
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.cancelOrClose();
                event.accepted = true;
                return;
            }
            const action = SessionService.available.find(a => a.key.toLowerCase() === event.text.toLowerCase());
            if (action) {
                root.trigger(action);
                event.accepted = true;
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: buttons.implicitWidth + padding * 2
        height: column.implicitHeight + padding * 2
        readonly property real padding: Math.round(Style.fontSize * 1.5)
        radius: Style.radius * 2.5
        color: Theme.background
        border.width: 1
        border.color: Theme.border

        // Swallow clicks so they don't close the menu.
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: column
            anchors.centerIn: parent
            spacing: Style.fontSize

            RowLayout {
                id: buttons
                spacing: Math.round(Style.fontSize * 0.8)

                Repeater {
                    model: SessionService.available

                    SessionMenuButton {
                        required property var modelData
                        action: modelData
                        pending: root.pendingId === modelData.id
                        remaining: root.remaining
                        onActivated: root.trigger(modelData)
                    }
                }
            }

            VText {
                Layout.alignment: Qt.AlignHCenter
                text: root.pendingId !== ""
                      ? "Click again or press the key to do it now · Esc to cancel"
                      : "Press a button's letter, or Esc to close"
                color: Theme.textMuted
                font.pixelSize: Style.fontSize * 0.9
            }
        }
    }
}
