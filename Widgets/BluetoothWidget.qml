import QtQuick
import Quickshell.Bluetooth
import qs.Commons
import qs.Components

// Shows Bluetooth state. Left click: Bluetooth panel (or on/off, see the
// clickAction option). Right click: on/off.
BarWidget {
    id: root

    panelName: "bluetooth"

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: !!adapter && adapter.enabled
    readonly property var connected: adapter ? adapter.devices.values.filter(d => d.connected) : []

    shown: !!adapter
    implicitWidth: shown ? pill.implicitWidth : 0
    implicitHeight: shown ? pill.implicitHeight : 0

    BarPill {
        id: pill
        anchors.centerIn: parent
        vertical: root.vertical
        barThickness: root.barThickness
        fontSize: root.fontSize
        icon: !root.enabled ? "bluetooth-off" : (root.connected.length > 0 ? "bluetooth-connected" : "bluetooth")
        iconColor: !root.enabled ? Theme.textMuted : (root.connected.length > 0 ? Theme.accent : Theme.text)
        text: root.options.showDeviceName && root.connected.length > 0
              ? (root.connected.length === 1 ? (root.connected[0].name || root.connected[0].deviceName) : `${root.connected.length} devices`)
              : ""
        textOnVertical: false
        maxTextWidth: root.fontSize * 12

        active: root.panelOpen
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton || root.options.clickAction === "toggle") {
                if (root.adapter)
                    root.adapter.enabled = !root.adapter.enabled;
            } else {
                root.togglePanel();
            }
        }
    }
}
