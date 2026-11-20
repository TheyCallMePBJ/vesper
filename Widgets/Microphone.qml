import QtQuick
import Quickshell
import qs.Commons
import qs.Components
import qs.Services

// Left click: mute. Scroll: input volume. Right click: run the configured command.
BarWidget {
    id: root

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
        acceptedButtons: root.options.rightClickCommand ? (Qt.LeftButton | Qt.RightButton) : Qt.LeftButton

        onWheelStep: dir => AudioService.changeMicVolume(dir)
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Quickshell.execDetached(["sh", "-c", root.options.rightClickCommand]);
            else
                AudioService.toggleMicMute();
        }
    }
}
