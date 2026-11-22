import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.Commons
import qs.Components
import qs.Services

// Output and input volume, device choice and per-app volume. Opened from the
// volume and microphone widgets.
BarPanel {
    id: root

    panelWidth: Math.round(Style.fontSize * 26)

    // Volumes of app streams and non-default devices are only readable while
    // tracked.
    PwObjectTracker {
        objects: AudioService.playbackStreams.concat(AudioService.sinks, AudioService.sources)
    }

    PanelHeader {
        text: "Output"
        icon: "volume"
    }

    VolumeRow {
        node: AudioService.sink
        icon: AudioService.volumeIcon(AudioService.volume, AudioService.muted)
    }

    DeviceList {
        devices: AudioService.sinks
        current: AudioService.sink
        onPicked: node => AudioService.setDefaultSink(node)
    }

    PanelHeader {
        text: "Input"
        icon: "microphone"
        Layout.topMargin: Math.round(Style.fontSize * 0.4)
    }

    VolumeRow {
        node: AudioService.source
        icon: AudioService.micMuted ? "microphone-off" : "microphone"
    }

    DeviceList {
        devices: AudioService.sources
        current: AudioService.source
        onPicked: node => AudioService.setDefaultSource(node)
    }

    PanelHeader {
        visible: AudioService.playbackStreams.length > 0
        text: "Apps"
        icon: "apps"
        Layout.topMargin: Math.round(Style.fontSize * 0.4)
    }

    Repeater {
        model: AudioService.playbackStreams

        ColumnLayout {
            id: stream
            required property PwNode modelData
            readonly property var props: modelData.properties || {}

            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                spacing: Math.round(Style.fontSize * 0.5)

                IconImage {
                    id: appIcon
                    readonly property string found: AppIcons.firstFound([stream.props["application.icon-name"], stream.props["application.process.binary"], stream.props["application.name"]])
                    visible: found !== ""
                    implicitSize: Math.round(Style.fontSize * 1.2)
                    source: found
                }
                VIcon {
                    visible: appIcon.found === ""
                    icon: "app-window"
                    color: Theme.textMuted
                    size: Math.round(Style.fontSize * 1.2)
                }
                VText {
                    Layout.fillWidth: true
                    text: {
                        const app = AudioService.nodeName(stream.modelData);
                        const media = stream.props["media.name"] || "";
                        return media && media !== app ? `${app} · ${media}` : app;
                    }
                    elide: Text.ElideRight
                    color: Theme.textMuted
                    font.pixelSize: Style.fontSize * 0.9
                }
            }

            VolumeRow {
                node: stream.modelData
                icon: AudioService.volumeIcon(node && node.audio ? node.audio.volume : 0, node && node.audio ? node.audio.muted : false)
            }
        }
    }

    // ---- Pieces ----------------------------------------------------------

    component PanelHeader: RowLayout {
        property string text
        property string icon
        Layout.fillWidth: true
        spacing: Math.round(Style.fontSize * 0.5)

        VIcon {
            icon: parent.icon
            color: Theme.accent
        }
        VText {
            Layout.fillWidth: true
            text: parent.text
            font.bold: true
        }
    }

    // Mute button and slider for one node.
    component VolumeRow: RowLayout {
        id: row
        property PwNode node
        property string icon
        readonly property bool ready: !!(node && node.audio)

        Layout.fillWidth: true
        spacing: Math.round(Style.fontSize * 0.3)
        enabled: ready

        VIconButton {
            iconName: row.icon
            iconColor: row.ready && row.node.audio.muted ? Theme.textMuted : Theme.text
            tooltip: row.ready && row.node.audio.muted ? "Unmute" : "Mute"
            onClicked: row.node.audio.muted = !row.node.audio.muted
        }
        VSlider {
            Layout.fillWidth: true
            value: row.ready ? row.node.audio.volume : 0
            formatValue: v => Math.round(v * 100) + "%"
            onChangedByUser: v => {
                row.node.audio.volume = v;
                if (v > 0 && row.node.audio.muted)
                    row.node.audio.muted = false;
            }
        }
    }

    // Pick the default device. Hidden when there's only one.
    component DeviceList: ColumnLayout {
        id: list
        property var devices: []
        property PwNode current
        signal picked(PwNode node)

        visible: devices.length > 1
        Layout.fillWidth: true
        spacing: 2

        Repeater {
            model: list.devices

            MouseArea {
                id: device
                required property PwNode modelData
                readonly property bool selected: modelData === list.current

                Layout.fillWidth: true
                implicitHeight: Math.round(Style.fontSize * 2.1)
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: list.picked(modelData)

                Rectangle {
                    anchors.fill: parent
                    radius: Style.radius
                    color: device.selected ? Theme.surface : (device.containsMouse ? Qt.alpha(Theme.surface, 0.5) : "transparent")
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(Style.fontSize * 0.6)
                    anchors.rightMargin: Math.round(Style.fontSize * 0.6)
                    spacing: Math.round(Style.fontSize * 0.6)

                    VIcon {
                        icon: device.selected ? "circle-dot" : "circle"
                        color: device.selected ? Theme.accent : Theme.textMuted
                        size: Style.fontSize * 1.1
                    }
                    VText {
                        Layout.fillWidth: true
                        text: AudioService.nodeName(device.modelData)
                        elide: Text.ElideRight
                        color: device.selected ? Theme.text : Theme.textMuted
                    }
                }
            }
        }
    }
}
