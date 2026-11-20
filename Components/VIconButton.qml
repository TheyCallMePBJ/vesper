import QtQuick
import QtQuick.Controls.Basic as T
import qs.Commons

// Square icon-only button. Set `tooltip` for a hover hint.
T.AbstractButton {
    id: root

    property string iconName: ""
    property string tooltip: ""
    property color iconColor: Theme.text
    property real size: Math.round(Style.fontSize * 2.2)

    implicitWidth: size
    implicitHeight: size
    hoverEnabled: true
    opacity: enabled ? 1 : 0.35

    contentItem: VIcon {
        icon: root.iconName
        color: root.iconColor
        size: root.size * 0.55
    }

    background: Rectangle {
        radius: Style.radius
        color: root.down ? Theme.surfaceAlt : (root.hovered ? Theme.surface : "transparent")
        Behavior on color { ColorAnimation { duration: Style.animationDuration } }
    }

    T.ToolTip {
        visible: root.tooltip !== "" && root.hovered
        delay: 500
        text: root.tooltip
        padding: Math.round(Style.fontSize * 0.45)
        contentItem: VText {
            text: root.tooltip
            font.pixelSize: Style.fontSize * 0.9
        }
        background: Rectangle {
            radius: Style.radius
            color: Theme.surface
            border.width: 1
            border.color: Theme.border
        }
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
