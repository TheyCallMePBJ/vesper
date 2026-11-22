import QtQuick
import Quickshell
import qs.Commons
import qs.Components
import qs.Services

// Left click: audio panel (or mute, see the clickAction option). Middle click:
// mute. Scroll: volume. Right click: run the configured command.
BarWidget {
    id: root

    panelName: "audio"

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    BarPill {
        id: pill
        anchors.centerIn: parent
        vertical: root.vertical
        barThickness: root.barThickness
        fontSize: root.fontSize
        icon: AudioService.volumeIcon(AudioService.volume, AudioService.muted)
        iconColor: AudioService.muted ? Theme.textMuted : Theme.text
        text: root.options.showPercent ? Math.round(AudioService.volume * 100) + "%" : ""
        textColor: AudioService.muted ? Theme.textMuted : Theme.text
        handlesWheel: true
        active: root.panelOpen
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | (root.options.rightClickCommand ? Qt.RightButton : 0)

        onWheelStep: dir => AudioService.changeVolume(dir)
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Quickshell.execDetached(["sh", "-c", root.options.rightClickCommand]);
            else if (mouse.button === Qt.MiddleButton || root.options.clickAction === "mute")
                AudioService.toggleMute();
            else
                root.togglePanel();
        }
    }
}
