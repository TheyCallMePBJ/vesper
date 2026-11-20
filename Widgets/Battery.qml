import QtQuick
import Quickshell.Services.UPower
import qs.Commons
import qs.Components

// Laptop battery. Hidden on machines without one.
BarWidget {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool present: !!device && device.ready && device.isLaptopBattery && device.isPresent
    readonly property real percent: present ? Math.round(device.percentage * 100) : 0
    readonly property bool charging: present && (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.FullyCharged || device.state === UPowerDeviceState.PendingCharge)
    readonly property bool low: !charging && percent <= root.options.warningPercent

    shown: present
    implicitWidth: shown ? pill.implicitWidth : 0
    implicitHeight: shown ? pill.implicitHeight : 0

    BarPill {
        id: pill
        anchors.centerIn: parent
        vertical: root.vertical
        barThickness: root.barThickness
        fontSize: root.fontSize
        interactive: false
        icon: root.charging ? "battery-charging"
              : root.percent >= 88 ? "battery-4"
              : root.percent >= 63 ? "battery-3"
              : root.percent >= 38 ? "battery-2"
              : root.percent >= 13 ? "battery-1" : "battery"
        iconColor: root.low ? Theme.error : (root.charging ? Theme.success : Theme.text)
        text: root.options.showPercent ? root.percent + "%" : ""
        textColor: root.low ? Theme.error : Theme.text
    }
}
