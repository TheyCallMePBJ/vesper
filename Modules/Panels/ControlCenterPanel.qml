import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Widgets
import qs.Commons
import qs.Components
import qs.Services

// Quick settings: volume and mic, toggles, the current media player, and
// shortcuts to the settings window and session menu.
BarPanel {
    id: root

    panelWidth: Math.round(Style.fontSize * 26)

    readonly property string user: Quickshell.env("USER") || ""
    property string host: ""
    property real uptimeSeconds: 0

    FileView {
        path: "/etc/hostname"
        onLoaded: root.host = text().trim()
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root.uptimeSeconds = parseFloat(text()) || 0
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: uptimeFile.reload()
    }

    function formatUptime(s) {
        const days = Math.floor(s / 86400);
        const hours = Math.floor(s % 86400 / 3600);
        const minutes = Math.floor(s % 3600 / 60);
        if (days > 0)
            return `${days}d ${hours}h`;
        return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
    }

    // ---- Header ------------------------------------------------------------

    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(Style.fontSize * 0.7)

        Rectangle {
            implicitWidth: Math.round(Style.fontSize * 2.8)
            implicitHeight: implicitWidth
            radius: width / 2
            color: Theme.surface

            VIcon {
                anchors.centerIn: parent
                icon: "user"
                color: Theme.accent
                size: Style.fontSize * 1.5
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            VText {
                Layout.fillWidth: true
                text: root.host ? `${root.user}@${root.host}` : root.user
                font.bold: true
                elide: Text.ElideRight
            }
            VText {
                visible: root.uptimeSeconds > 0
                text: "Up " + root.formatUptime(root.uptimeSeconds)
                color: Theme.textMuted
                font.pixelSize: Style.fontSize * 0.88
            }
        }

        VIconButton {
            iconName: "settings"
            tooltip: "Settings"
            onClicked: Panels.openSettings(root.screen)
        }
        VIconButton {
            iconName: "power"
            tooltip: "Session menu"
            onClicked: Panels.openSession(root.screen)
        }
    }

    // ---- Sliders -----------------------------------------------------------

    Card {
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(Style.fontSize * 0.2)

            SliderRow {
                icon: AudioService.volumeIcon(AudioService.volume, AudioService.muted)
                muted: AudioService.muted
                value: AudioService.volume
                enabled: AudioService.sinkReady
                tooltip: AudioService.muted ? "Unmute" : "Mute"
                onToggle: AudioService.toggleMute()
                onMoved: v => AudioService.setVolume(v)
                onMore: Panels.openPanel("audio", Panels.findAnchor("audio", root.screen))
            }
            SliderRow {
                icon: AudioService.micMuted ? "microphone-off" : "microphone"
                muted: AudioService.micMuted
                value: AudioService.micVolume
                enabled: AudioService.sourceReady
                tooltip: AudioService.micMuted ? "Unmute microphone" : "Mute microphone"
                onToggle: AudioService.toggleMicMute()
                onMoved: v => AudioService.setMicVolume(v)
                onMore: Panels.openPanel("audio", Panels.findAnchor("audio", root.screen))
            }
        }
    }

    // ---- Toggles -----------------------------------------------------------

    GridLayout {
        id: toggles
        Layout.fillWidth: true
        columns: 2
        rowSpacing: Math.round(Style.fontSize * 0.5)
        columnSpacing: Math.round(Style.fontSize * 0.5)

        readonly property var adapter: Bluetooth.defaultAdapter
        readonly property var connectedDevices: adapter ? adapter.devices.values.filter(d => d.connected) : []

        QuickToggle {
            visible: !!toggles.adapter
            icon: toggles.adapter && toggles.adapter.enabled ? (toggles.connectedDevices.length > 0 ? "bluetooth-connected" : "bluetooth") : "bluetooth-off"
            label: "Bluetooth"
            detail: !toggles.adapter || !toggles.adapter.enabled ? "Off"
                  : toggles.connectedDevices.length === 1 ? (toggles.connectedDevices[0].name || toggles.connectedDevices[0].deviceName)
                  : toggles.connectedDevices.length > 1 ? `${toggles.connectedDevices.length} devices` : "On"
            on: !!toggles.adapter && toggles.adapter.enabled
            onClicked: toggles.adapter.enabled = !toggles.adapter.enabled
        }

        QuickToggle {
            icon: NotificationService.doNotDisturb ? "bell-off" : "bell"
            label: "Do not disturb"
            detail: NotificationService.doNotDisturb ? "On" : "Off"
            on: NotificationService.doNotDisturb
            onClicked: NotificationService.setDoNotDisturb(!NotificationService.doNotDisturb)
        }

        QuickToggle {
            readonly property int profile: PowerProfiles.profile
            readonly property var order: PowerProfiles.hasPerformanceProfile
                ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
                : [PowerProfile.PowerSaver, PowerProfile.Balanced]
            icon: profile === PowerProfile.PowerSaver ? "leaf" : profile === PowerProfile.Performance ? "rocket" : "scale"
            label: "Power profile"
            detail: profile === PowerProfile.PowerSaver ? "Power saver" : profile === PowerProfile.Performance ? "Performance" : "Balanced"
            on: profile !== PowerProfile.Balanced
            onClicked: PowerProfiles.profile = order[(order.indexOf(profile) + 1) % order.length]
        }

        QuickToggle {
            icon: AudioService.micMuted ? "microphone-off" : "microphone"
            label: "Microphone"
            detail: AudioService.micMuted ? "Muted" : "On"
            on: !AudioService.micMuted
            enabled: AudioService.sourceReady
            onClicked: AudioService.toggleMicMute()
        }
    }

    // ---- Media -------------------------------------------------------------

    Card {
        id: media
        visible: MediaService.hasPlayer

        readonly property var player: MediaService.player

        // Players only report their position when asked.
        Timer {
            interval: 1000
            repeat: true
            running: media.visible && media.player && media.player.isPlaying
            onTriggered: media.player.positionChanged()
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(Style.fontSize * 0.8)

            ClippingRectangle {
                implicitWidth: Math.round(Style.fontSize * 4)
                implicitHeight: implicitWidth
                radius: Style.radius
                color: Theme.surfaceAlt

                Image {
                    id: art
                    anchors.fill: parent
                    source: media.player ? media.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: width * 2
                    sourceSize.height: height * 2
                    asynchronous: true
                }
                VIcon {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    icon: "music"
                    color: Theme.textMuted
                    size: Style.fontSize * 1.8
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                VText {
                    Layout.fillWidth: true
                    text: MediaService.title || "Nothing playing"
                    font.bold: true
                    elide: Text.ElideRight
                }
                VText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: MediaService.artist
                    color: Theme.textMuted
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.topMargin: 2
                    spacing: 0

                    VIconButton {
                        iconName: "player-skip-back"
                        tooltip: "Previous"
                        enabled: !!media.player && media.player.canGoPrevious
                        onClicked: MediaService.previous()
                    }
                    VIconButton {
                        iconName: MediaService.isPlaying ? "player-pause" : "player-play"
                        tooltip: MediaService.isPlaying ? "Pause" : "Play"
                        enabled: !!media.player && media.player.canTogglePlaying
                        onClicked: MediaService.togglePlaying()
                    }
                    VIconButton {
                        iconName: "player-skip-forward"
                        tooltip: "Next"
                        enabled: !!media.player && media.player.canGoNext
                        onClicked: MediaService.next()
                    }
                }
            }
        }

        // Progress; click to seek.
        MouseArea {
            id: progress
            readonly property bool usable: !!media.player && media.player.lengthSupported && media.player.length > 0
            visible: usable
            Layout.fillWidth: true
            implicitHeight: 10
            cursorShape: media.player && media.player.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: mouse => {
                if (media.player && media.player.canSeek)
                    media.player.position = mouse.x / width * media.player.length;
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Theme.surfaceAlt

                Rectangle {
                    width: progress.usable ? parent.width * Math.max(0, Math.min(1, media.player.position / media.player.length)) : 0
                    height: parent.height
                    radius: 2
                    color: Theme.accent
                }
            }
        }
    }

    // ---- Pieces ------------------------------------------------------------

    component Card: Rectangle {
        default property alias content: cardBody.data
        Layout.fillWidth: true
        implicitHeight: cardBody.implicitHeight + Style.fontSize * 1.4
        radius: Style.radius * 1.5
        color: Qt.alpha(Theme.surface, 0.5)

        ColumnLayout {
            id: cardBody
            x: Style.fontSize * 0.7
            y: Style.fontSize * 0.7
            width: parent.width - Style.fontSize * 1.4
            spacing: Math.round(Style.fontSize * 0.5)
        }
    }

    component SliderRow: RowLayout {
        id: sliderRow
        property string icon
        property bool muted
        property real value
        property string tooltip
        signal toggle()
        signal moved(real value)
        signal more()

        Layout.fillWidth: true
        spacing: Math.round(Style.fontSize * 0.2)

        VIconButton {
            iconName: sliderRow.icon
            iconColor: sliderRow.muted ? Theme.textMuted : Theme.text
            tooltip: sliderRow.tooltip
            onClicked: sliderRow.toggle()
        }
        VSlider {
            Layout.fillWidth: true
            value: sliderRow.value
            formatValue: v => Math.round(v * 100) + "%"
            onChangedByUser: v => sliderRow.moved(v)
        }
        VIconButton {
            iconName: "chevron-right"
            tooltip: "Devices and apps"
            onClicked: sliderRow.more()
        }
    }

    component QuickToggle: MouseArea {
        id: tile
        property string icon
        property string label
        property string detail
        property bool on

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: Math.round(Style.fontSize * 3.4)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        opacity: enabled ? 1 : 0.4

        Rectangle {
            anchors.fill: parent
            radius: Style.radius * 1.5
            color: tile.on ? Theme.accent : (tile.pressed ? Theme.surfaceAlt : tile.containsMouse ? Theme.surface : Qt.alpha(Theme.surface, 0.5))
            Behavior on color { ColorAnimation { duration: Style.animationDuration } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Math.round(Style.fontSize * 0.8)
            anchors.rightMargin: Math.round(Style.fontSize * 0.8)
            spacing: Math.round(Style.fontSize * 0.7)

            VIcon {
                icon: tile.icon
                color: tile.on ? Theme.onAccent : Theme.text
                size: Style.fontSize * 1.4
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                VText {
                    Layout.fillWidth: true
                    text: tile.label
                    color: tile.on ? Theme.onAccent : Theme.text
                    font.bold: true
                    font.pixelSize: Style.fontSize * 0.92
                    elide: Text.ElideRight
                }
                VText {
                    Layout.fillWidth: true
                    text: tile.detail
                    color: tile.on ? Qt.alpha(Theme.onAccent, 0.8) : Theme.textMuted
                    font.pixelSize: Style.fontSize * 0.82
                    elide: Text.ElideRight
                }
            }
        }
    }
}
