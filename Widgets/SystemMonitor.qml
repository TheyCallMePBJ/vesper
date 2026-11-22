import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Components
import qs.Services

// CPU, memory, temperatures, GPU, disk and network at a glance. Values turn
// yellow / red above the thresholds in Settings → General. Click runs the
// configured command (e.g. a system monitor app).
BarWidget {
    id: root

    readonly property var sm: SystemMonitorService
    readonly property string mono: options.monospace ? Style.monoFontFamily : Style.fontFamily

    // Each shown stat: icon, text, a sample of its widest text (so the widget
    // doesn't change width as numbers change) and its warning level.
    readonly property var items: {
        const o = options;
        const out = [];
        const pct = v => v < 0 ? "--" : Math.round(v) + "%";
        const deg = v => v < 0 ? "--" : Math.round(v) + "°";
        if (o.showCpu) out.push({ icon: "cpu", text: pct(sm.cpuUsage), sample: "100%", level: sm.usageLevel(sm.cpuUsage) });
        if (o.showCpuTemp) out.push({ icon: "temperature", text: deg(sm.cpuTemp), sample: "100°", level: sm.tempLevel(sm.cpuTemp) });
        if (o.showMemory) out.push({ icon: "database", text: o.memoryAsPercent ? pct(sm.memUsage) : sm.formatBytes(sm.memUsed), sample: o.memoryAsPercent ? "100%" : "99.9G", level: sm.usageLevel(sm.memUsage) });
        if (o.showGpu && sm.gpuUsage >= 0) out.push({ icon: "device-desktop-analytics", text: pct(sm.gpuUsage), sample: "100%", level: sm.usageLevel(sm.gpuUsage) });
        if (o.showGpuTemp && sm.gpuTemp >= 0) out.push({ icon: "temperature-sun", text: deg(sm.gpuTemp), sample: "100°", level: sm.tempLevel(sm.gpuTemp) });
        if (o.showDisk) out.push({ icon: "device-sd-card", text: pct(sm.diskUsage), sample: "100%", level: sm.usageLevel(sm.diskUsage) });
        if (o.showNetwork) {
            out.push({ icon: "arrow-down", text: sm.formatBytes(sm.netDown, true), sample: "99.9M/s", level: "" });
            out.push({ icon: "arrow-up", text: sm.formatBytes(sm.netUp, true), sample: "99.9M/s", level: "" });
        }
        return out;
    }

    Component.onCompleted: SystemMonitorService.users++
    Component.onDestruction: SystemMonitorService.users--

    shown: items.length > 0
    implicitWidth: shown ? mouse.implicitWidth : 0
    implicitHeight: shown ? mouse.implicitHeight : 0

    MouseArea {
        id: mouse
        anchors.centerIn: parent
        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight
        acceptedButtons: root.options.clickCommand ? Qt.LeftButton : Qt.NoButton
        cursorShape: root.options.clickCommand ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: Quickshell.execDetached(["sh", "-c", root.options.clickCommand])

        LineLayout {
            id: row
            anchors.centerIn: parent
            vertical: root.vertical
            spacing: Math.round(root.fontSize * (root.vertical ? 0.4 : 0.7))

            Repeater {
                model: root.items

                LineLayout {
                    id: stat
                    required property var modelData
                    readonly property color color: modelData.level === "critical" ? Theme.error
                                                 : modelData.level === "warning" ? Theme.warning : Theme.text

                    Layout.alignment: Qt.AlignCenter
                    vertical: root.vertical
                    spacing: Math.round(root.fontSize * 0.25)

                    VIcon {
                        Layout.alignment: Qt.AlignCenter
                        icon: stat.modelData.icon
                        color: stat.modelData.level ? stat.color : Theme.textMuted
                        size: Math.round(root.fontSize * 1.15)
                    }
                    VText {
                        id: valueText
                        Layout.alignment: Qt.AlignCenter
                        // Fixed width on horizontal bars so neighbours don't jiggle.
                        Layout.preferredWidth: root.vertical ? implicitWidth : sampleMetrics.advanceWidth
                        horizontalAlignment: root.vertical ? Text.AlignHCenter : Text.AlignLeft
                        text: stat.modelData.text
                        color: stat.color
                        font.family: root.mono
                        font.pixelSize: root.vertical ? root.fontSize * 0.75 : root.fontSize * 0.92

                        TextMetrics {
                            id: sampleMetrics
                            font: valueText.font
                            text: stat.modelData.sample
                        }
                    }
                }
            }
        }
    }
}
