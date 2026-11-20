import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Components

// One large button in the session menu.
MouseArea {
    id: root

    required property var action
    property bool pending: false
    property int remaining: 0

    signal activated

    readonly property real size: Math.round(Style.fontSize * 8)
    readonly property color fg: pending ? Theme.onAccent : (action.id === "shutdown" || action.id === "reboot" ? (containsMouse ? Theme.error : Theme.text) : Theme.text)

    implicitWidth: size
    implicitHeight: size
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: activated()

    Rectangle {
        anchors.fill: parent
        radius: Style.radius * 2
        color: root.pending ? Theme.accent : (root.pressed ? Theme.surfaceAlt : (root.containsMouse ? Qt.lighter(Theme.surface, 1.12) : Theme.surface))
        border.width: 1
        border.color: root.containsMouse && !root.pending ? Theme.accent : Theme.border
        Behavior on color { ColorAnimation { duration: Style.animationDuration } }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Math.round(Style.fontSize * 0.4)

        VIcon {
            Layout.alignment: Qt.AlignHCenter
            icon: root.action.icon
            color: root.fg
            size: Style.fontSize * 2.6
        }
        VText {
            Layout.alignment: Qt.AlignHCenter
            text: root.pending ? `${root.action.label} in ${root.remaining}` : root.action.label
            color: root.fg
            font.bold: root.pending
        }
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Math.round(Style.fontSize * 1.7)
            implicitHeight: implicitWidth
            radius: Style.radius
            color: "transparent"
            border.width: 1
            border.color: root.pending ? Theme.onAccent : Theme.border
            VText {
                anchors.centerIn: parent
                text: root.action.key
                color: root.pending ? Theme.onAccent : Theme.textMuted
                font.pixelSize: Style.fontSize * 0.85
            }
        }
    }
}
