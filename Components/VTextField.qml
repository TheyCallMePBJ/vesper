import QtQuick
import QtQuick.Controls.Basic as T
import qs.Commons

// Single-line text input. Bind `value`; `changedByUser(text)` fires when the
// user presses Enter or leaves the field (not on every keystroke).
T.TextField {
    id: root

    property string value: ""
    signal changedByUser(string text)

    text: value
    color: Theme.text
    placeholderTextColor: Theme.textMuted
    selectionColor: Theme.accent
    selectedTextColor: Theme.onAccent
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize
    implicitHeight: Math.round(Style.fontSize * 2.4)
    implicitWidth: Math.round(Style.fontSize * 14)
    leftPadding: Math.round(Style.fontSize * 0.8)
    rightPadding: leftPadding
    verticalAlignment: TextInput.AlignVCenter
    hoverEnabled: true
    selectByMouse: true

    onEditingFinished: {
        if (text !== value)
            changedByUser(text);
        text = Qt.binding(() => root.value);
    }
    Keys.onEscapePressed: event => {
        text = Qt.binding(() => root.value);
        focus = false;
        event.accepted = true;
    }

    background: Rectangle {
        radius: Style.radius
        color: Theme.surface
        border.width: 1
        border.color: root.activeFocus ? Theme.accent : (root.hovered ? Qt.lighter(Theme.border, 1.2) : Theme.border)
    }
}
