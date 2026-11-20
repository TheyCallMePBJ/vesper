import QtQuick
import Quickshell
import qs.Commons
import qs.Components

BarWidget {
    id: root

    readonly property string format: vertical ? options.formatVertical : options.format

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    SystemClock {
        id: clock
        // Only tick every second if the format shows seconds.
        precision: /s/.test(root.format.replace(/'[^']*'/g, "")) ? SystemClock.Seconds : SystemClock.Minutes
    }

    VText {
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, root.format)
        font.pixelSize: root.fontSize
        horizontalAlignment: Text.AlignHCenter
    }
}
