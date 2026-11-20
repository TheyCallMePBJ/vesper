import QtQuick
import Quickshell.Services.UPower
import qs.Commons
import qs.Components

// Current power profile. Left click cycles to the next one.
// Needs power-profiles-daemon (or tuned-ppd).
BarWidget {
    id: root

    readonly property int profile: PowerProfiles.profile
    readonly property var order: PowerProfiles.hasPerformanceProfile
        ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
        : [PowerProfile.PowerSaver, PowerProfile.Balanced]

    readonly property var info: ({
        [PowerProfile.PowerSaver]: { icon: "leaf", label: "Saver" },
        [PowerProfile.Balanced]: { icon: "scale", label: "Balanced" },
        [PowerProfile.Performance]: { icon: "rocket", label: "Performance" }
    })
    readonly property var current: info[profile] || info[PowerProfile.Balanced]

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    BarPill {
        id: pill
        anchors.centerIn: parent
        vertical: root.vertical
        barThickness: root.barThickness
        fontSize: root.fontSize
        icon: root.current.icon
        iconColor: root.profile === PowerProfile.Performance ? Theme.warning
                 : root.profile === PowerProfile.PowerSaver ? Theme.success : Theme.text
        text: root.options.showLabel ? root.current.label : ""
        textOnVertical: false

        onClicked: {
            const i = root.order.indexOf(root.profile);
            PowerProfiles.profile = root.order[(i + 1) % root.order.length];
        }
    }
}
