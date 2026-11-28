import QtQuick
import qs.Commons
import qs.Components
import qs.Services

// Brightness of the screen this bar is on. Scroll to change it, click for the
// brightness panel. Hidden if the screen's brightness can't be controlled.
BarWidget {
    id: root

    readonly property var monitor: BrightnessService.forScreen(screen)
    readonly property real value: monitor ? monitor.value : 0

    panelName: "brightness"
    shown: !!monitor && monitor.available
    implicitWidth: shown ? pill.implicitWidth : 0
    implicitHeight: shown ? pill.implicitHeight : 0

    BarPill {
        id: pill
        anchors.centerIn: parent
        vertical: root.vertical
        barThickness: root.barThickness
        fontSize: root.fontSize
        icon: root.value < 0.5 ? "brightness-down" : "brightness-up"
        text: root.options.showPercent ? Math.round(root.value * 100) + "%" : ""
        handlesWheel: true
        active: root.panelOpen

        onWheelStep: dir => BrightnessService.change(root.monitor, dir)
        onClicked: root.togglePanel()
    }
}
