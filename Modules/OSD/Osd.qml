import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Components
import qs.Services

// Shows the new level for a moment when the volume or mic changes (from any
// source: keys, IPC, the bar or another app) or brightness is changed through
// Vesper. Click-through.
Scope {
    id: root

    // What's being shown: "volume", "mic" or "brightness".
    property string kind: "volume"
    property bool shown: false
    // Keeps the window around while it fades out.
    property bool loaded: false
    property ShellScreen screen: null

    // Changes right after startup or a device switch are the new device
    // reporting its level, not the user changing it.
    property bool ready: false

    readonly property bool isMic: kind === "mic"
    // The monitor whose brightness changed.
    property var brightnessMonitor: null
    readonly property real level: kind === "brightness" ? (brightnessMonitor ? brightnessMonitor.value : 0)
                                : isMic ? AudioService.micVolume : AudioService.volume
    readonly property bool muted: kind === "brightness" ? false : isMic ? AudioService.micMuted : AudioService.muted
    readonly property string icon: kind === "brightness" ? (level < 0.5 ? "brightness-down" : "brightness-up")
                                 : isMic ? (muted ? "microphone-off" : "microphone") : AudioService.volumeIcon(level, muted)

    function show(what, onScreen) {
        if (!ready || !Settings.osd.enabled)
            return;
        // Those panels show the level themselves.
        if (Panels.panel === "controlCenter" || (Panels.panel === "audio" && what !== "brightness"))
            return;
        // Switching kind or screen restarts the popup there.
        if (onScreen && shown && screen !== onScreen)
            shown = false;
        kind = what;
        if (!shown)
            screen = onScreen || Panels.focusedScreen();
        shown = true;
        loaded = true;
        hideTimer.restart();
    }

    function settle() {
        ready = false;
        settleTimer.restart();
    }

    Component.onCompleted: settle()

    Timer {
        id: settleTimer
        interval: 1000
        onTriggered: root.ready = true
    }

    Timer {
        id: hideTimer
        interval: Math.max(300, Settings.osd.timeout || 1500)
        onTriggered: {
            root.shown = false;
            unloadTimer.restart();
        }
    }

    Timer {
        id: unloadTimer
        interval: Style.animationDuration + 50
        onTriggered: if (!root.shown) root.loaded = false
    }

    Connections {
        target: BrightnessService
        function onChangedByUser(monitor) {
            root.brightnessMonitor = monitor;
            root.show("brightness", monitor.modelData);
        }
    }

    Connections {
        target: AudioService
        function onSinkChanged() { root.settle(); }
        function onSourceChanged() { root.settle(); }
    }

    Connections {
        target: AudioService.sinkReady ? AudioService.sink.audio : null
        function onVolumeChanged() { root.show("volume"); }
        function onMutedChanged() { root.show("volume"); }
    }

    Connections {
        target: AudioService.sourceReady ? AudioService.source.audio : null
        function onVolumeChanged() { root.show("mic"); }
        function onMutedChanged() { root.show("mic"); }
    }

    LazyLoader {
        active: root.loaded

        PanelWindow {
            id: win

            readonly property string position: ["top", "bottom", "left", "right"].includes(Settings.osd.position) ? Settings.osd.position : "bottom"
            readonly property bool vertical: position === "left" || position === "right"
            readonly property real margin: Math.round(Style.fontSize * 2.5)

            screen: root.screen
            WlrLayershell.namespace: "vesper-osd"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 0
            mask: Region {}
            color: "transparent"

            anchors {
                top: position === "top"
                bottom: position === "bottom"
                left: position === "left"
                right: position === "right"
            }
            margins {
                top: margin
                bottom: margin
                left: margin
                right: margin
            }

            implicitWidth: card.width
            implicitHeight: card.height

            Rectangle {
                id: card

                readonly property real thickness: Math.round(Style.fontSize * 3.2)
                readonly property real length: Math.round(Style.fontSize * 18)
                readonly property real pad: Math.round(Style.fontSize * 0.9)

                width: win.vertical ? thickness : length
                height: win.vertical ? length : thickness
                radius: Math.min(width, height) / 2
                color: Theme.background
                border.width: 1
                border.color: Theme.border
                opacity: root.shown ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Style.animationDuration } }

                LineLayout {
                    anchors.fill: parent
                    anchors.margins: card.pad
                    anchors.leftMargin: win.vertical ? card.pad : card.pad * 1.4
                    anchors.rightMargin: win.vertical ? card.pad : card.pad * 1.4
                    anchors.topMargin: win.vertical ? card.pad * 1.4 : card.pad
                    anchors.bottomMargin: win.vertical ? card.pad * 1.4 : card.pad
                    vertical: win.vertical
                    spacing: Math.round(Style.fontSize * 0.8)

                    VIcon {
                        Layout.alignment: Qt.AlignCenter
                        icon: root.icon
                        color: root.muted ? Theme.textMuted : Theme.text
                        size: Style.fontSize * 1.5
                    }

                    // Level bar.
                    Rectangle {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: !win.vertical
                        Layout.fillHeight: win.vertical
                        implicitWidth: win.vertical ? 6 : 0
                        implicitHeight: win.vertical ? 0 : 6
                        radius: 3
                        color: Theme.surfaceAlt

                        Rectangle {
                            readonly property real fraction: Math.max(0, Math.min(1, root.level))
                            width: win.vertical ? parent.width : parent.width * fraction
                            height: win.vertical ? parent.height * fraction : parent.height
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            radius: 3
                            color: root.muted ? Theme.textMuted : Theme.accent
                            Behavior on width { NumberAnimation { duration: 80 } }
                            Behavior on height { NumberAnimation { duration: 80 } }
                        }
                    }

                    VText {
                        Layout.alignment: Qt.AlignCenter
                        Layout.preferredWidth: win.vertical ? -1 : Style.fontSize * 2.8
                        horizontalAlignment: win.vertical ? Text.AlignHCenter : Text.AlignRight
                        text: Math.round(root.level * 100)
                        color: root.muted ? Theme.textMuted : Theme.text
                        font.pixelSize: win.vertical ? Style.fontSize * 0.85 : Style.fontSize
                    }
                }
            }
        }
    }
}
