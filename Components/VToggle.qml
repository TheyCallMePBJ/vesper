import QtQuick
import QtQuick.Controls.Basic as T
import qs.Commons

// On/off switch. Bind `value`; handle `changedByUser(bool)` to save the change.
// The switch snaps back to `value`, so it always shows the real setting.
T.Switch {
    id: root

    property bool value: false
    signal changedByUser(bool value)

    checked: value
    hoverEnabled: true
    padding: 0
    implicitWidth: indicator.implicitWidth
    implicitHeight: indicator.implicitHeight
    opacity: enabled ? 1 : 0.4

    onToggled: {
        changedByUser(checked);
        checked = Qt.binding(() => root.value);
    }

    indicator: Rectangle {
        implicitWidth: Math.round(Style.fontSize * 3)
        implicitHeight: Math.round(Style.fontSize * 1.6)
        x: root.leftPadding
        y: (root.height - height) / 2
        radius: height / 2
        color: root.checked ? Theme.accent : Theme.surfaceAlt
        border.width: root.checked ? 0 : 1
        border.color: Theme.border
        Behavior on color { ColorAnimation { duration: Style.animationDuration } }

        Rectangle {
            readonly property real inset: 3
            width: parent.height - inset * 2
            height: width
            radius: width / 2
            y: inset
            x: root.checked ? parent.width - width - inset : inset
            color: root.checked ? Theme.onAccent : Theme.textMuted
            Behavior on x { NumberAnimation { duration: Style.animationDuration; easing.type: Easing.OutCubic } }
        }
    }

    contentItem: Item {}

    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
