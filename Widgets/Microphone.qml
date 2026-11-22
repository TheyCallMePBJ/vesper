import QtQuick
import Quickshell
import qs.Commons
import qs.Components
import qs.Services

// Left click: audio panel (or mute, see the clickAction option). Middle click:
// mute. Scroll: input volume. Right click: run the configured command.
BarWidget {
    id: root

    panelName: "audio"

    shown: AudioService.sourceReady
    implicitWidth: shown ? pill.implicitWidth : 0
    implicitHeight: shown ? pill.implicitHeight : 0

    BarPill {
        id: pill
        anchors.centerIn: parent
        vertical: root.vertical
        barThickness: root.barThickness
        fontSize: root.fontSize
        icon: AudioService.micMuted ? "microphone-off" : "microphone"
        iconColor: AudioService.micMuted ? Theme.textMuted : Theme.text
        text: root.options.showPercent ? Math.round(AudioService.micVolume * 100) + "%" : ""
        textColor: AudioService.micMuted ? Theme.textMuted : Theme.text
        handlesWheel: true
        active: root.panelOpen
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | (root.options.rightClickCommand ? Qt.RightButton : 0)

        onWheelStep: dir => AudioService.changeMicVolume(dir)
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Quickshell.execDetached(["sh", "-c", root.options.rightClickCommand]);
            else if (mouse.button === Qt.MiddleButton || root.options.clickAction === "mute")
                AudioService.toggleMicMute();
            else
                root.togglePanel();
        }
    }
}
