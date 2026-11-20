import QtQuick
import qs.Commons
import qs.Components

// Fixed text, or the first line of a command's output refreshed on an interval.
BarWidget {
    id: root

    readonly property string displayText: options.command ? runner.output : (options.text || "")

    shown: displayText !== ""
    implicitWidth: shown ? label.implicitWidth : 0
    implicitHeight: shown ? label.implicitHeight : 0

    CommandRunner {
        id: runner
        command: root.options.command || ""
        interval: root.options.interval
    }

    VText {
        id: label
        anchors.centerIn: parent
        text: root.displayText
        color: root.options.color && Qt.color(root.options.color).valid ? root.options.color : Theme.text
        font.pixelSize: root.fontSize
        horizontalAlignment: Text.AlignHCenter
        width: root.vertical ? Math.min(implicitWidth, root.barThickness) : Math.min(implicitWidth, root.fontSize * 30)
        elide: Text.ElideRight
    }
}
