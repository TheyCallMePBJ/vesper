import QtQuick
import Quickshell
import qs.Commons
import qs.Components

// Date and time. Click to open the calendar.
BarWidget {
    id: root

    readonly property string format: vertical ? options.formatVertical : options.format
    readonly property real pad: Math.round(fontSize * 0.35)

    panelName: "calendar"
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    SystemClock {
        id: clock
        // Only tick every second if the format shows seconds.
        precision: /s/.test(root.format.replace(/'[^']*'/g, "")) ? SystemClock.Seconds : SystemClock.Minutes
    }

    MouseArea {
        id: mouse
        // Same hover background as BarPill: outside the content along the bar.
        anchors.centerIn: parent
        width: root.vertical ? Math.round(root.barThickness * 0.8) : parent.width + root.pad * 2
        height: root.vertical ? parent.height + root.pad * 2 : Math.round(root.barThickness * 0.8)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePanel()

        Rectangle {
            anchors.fill: parent
            radius: Style.radius
            color: mouse.pressed ? Theme.surfaceAlt : Theme.surface
            opacity: root.panelOpen || mouse.containsMouse || mouse.pressed ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Style.animationDuration } }
        }
    }

    VText {
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, root.format)
        font.pixelSize: root.fontSize
        horizontalAlignment: Text.AlignHCenter
    }
}
