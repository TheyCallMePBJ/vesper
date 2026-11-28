import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Components
import qs.Services

// Brightness sliders, one per screen that supports it (this screen first).
// Opened from the brightness widget.
BarPanel {
    id: root

    panelWidth: Math.round(Style.fontSize * 20)

    readonly property var monitors: BrightnessService.available.slice()
        .sort((a, b) => (b.name === root.screen.name) - (a.name === root.screen.name))

    // Pick up changes made with a monitor's own buttons.
    Component.onCompleted: BrightnessService.refreshAll()

    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(Style.fontSize * 0.5)

        VIcon {
            icon: "brightness-up"
            color: Theme.accent
        }
        VText {
            Layout.fillWidth: true
            text: "Brightness"
            font.bold: true
        }
    }

    Repeater {
        model: root.monitors

        ColumnLayout {
            id: row
            required property var modelData
            Layout.fillWidth: true
            spacing: 0

            // Which monitor, when there's more than one.
            VText {
                visible: root.monitors.length > 1
                Layout.leftMargin: Math.round(Style.fontSize * 2.6)
                text: row.modelData.name === root.screen.name ? `${row.modelData.name} · this screen` : row.modelData.name
                color: Theme.textMuted
                font.pixelSize: Style.fontSize * 0.85
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(Style.fontSize * 0.5)

                Item {
                    implicitWidth: Math.round(Style.fontSize * 2.1)
                    implicitHeight: implicitWidth
                    VIcon {
                        anchors.centerIn: parent
                        icon: row.modelData.value < 0.5 ? "brightness-down" : "brightness-up"
                    }
                }
                VSlider {
                    Layout.fillWidth: true
                    value: row.modelData.value
                    formatValue: v => Math.round(v * 100) + "%"
                    onChangedByUser: v => BrightnessService.set(row.modelData, v)
                }
            }
        }
    }

    VText {
        visible: root.monitors.length === 0
        Layout.fillWidth: true
        text: "No screen's brightness can be set."
        color: Theme.textMuted
        wrapMode: Text.Wrap
    }
}
