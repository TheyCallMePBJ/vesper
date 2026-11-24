import QtQuick
import qs.Commons
import qs.Components
import qs.Services

// The session menu key for one button. Click, then press a key; Esc cancels,
// Backspace goes back to the default.
VButton {
    id: capture
    property string actionId
    property bool listening: false

    implicitWidth: Math.round(Style.fontSize * 2.4)
    implicitHeight: Math.round(Style.fontSize * 2.4)
    leftPadding: 0
    rightPadding: 0
    text: listening ? "…" : SessionService.keyFor(actionId)
    style: listening ? "primary" : "default"
    contentItem: VText {
        text: capture.text
        color: capture.fg
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    onClicked: {
        listening = !listening;
        if (listening)
            forceActiveFocus();
    }
    onActiveFocusChanged: if (!activeFocus) listening = false

    Keys.onPressed: event => {
        if (!listening)
            return;
        event.accepted = true;
        if (event.key === Qt.Key_Escape) {
            listening = false;
            return;
        }
        if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) {
            SessionService.setKey(actionId, SessionService.defaultKeys[actionId]);
            listening = false;
            return;
        }
        // One printable character, without Ctrl/Alt/Super.
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
            return;
        const t = event.text;
        if (t.length !== 1 || /\s/.test(t) || t.charCodeAt(0) < 32)
            return;
        SessionService.setKey(actionId, t);
        listening = false;
    }
}
