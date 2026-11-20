import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts
import qs.Commons

// Button with optional icon. style: "default" | "primary" | "ghost" | "danger"
T.Button {
    id: root

    property string iconName: ""
    property string style: "default"

    readonly property color fg: style === "primary" ? Theme.onAccent : (style === "danger" ? Theme.error : Theme.text)
    readonly property color bg: {
        if (style === "primary")
            return down ? Qt.darker(Theme.accent, 1.15) : (hovered ? Qt.lighter(Theme.accent, 1.08) : Theme.accent);
        if (style === "ghost")
            return down ? Theme.surfaceAlt : (hovered ? Theme.surface : "transparent");
        return down ? Theme.surfaceAlt : (hovered ? Qt.lighter(Theme.surface, 1.12) : Theme.surface);
    }

    implicitHeight: Math.round(Style.fontSize * 2.4)
    leftPadding: text ? Style.fontSize : Math.round(Style.fontSize * 0.6)
    rightPadding: leftPadding
    hoverEnabled: true
    opacity: enabled ? 1 : 0.4

    contentItem: RowLayout {
        spacing: Math.round(Style.fontSize * 0.45)

        VIcon {
            visible: root.iconName !== ""
            icon: root.iconName
            color: root.fg
            size: Style.fontSize * 1.2
            Layout.alignment: Qt.AlignVCenter
        }
        VText {
            visible: root.text !== ""
            text: root.text
            color: root.fg
            Layout.alignment: Qt.AlignVCenter
        }
    }

    background: Rectangle {
        radius: Style.radius
        color: root.bg
        border.width: root.style === "default" ? 1 : 0
        border.color: Theme.border
        Behavior on color { ColorAnimation { duration: Style.animationDuration } }
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
