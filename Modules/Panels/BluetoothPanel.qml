import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.Commons
import qs.Components
import qs.Services

// Bluetooth on/off, connected and paired devices, and pairing new ones
// (scans while the panel is open).
BarPanel {
    id: root

    panelWidth: Math.round(Style.fontSize * 26)

    // Address of the device whose row shows its buttons.
    property string expanded: ""

    Component.onCompleted: BluetoothService.scanners++
    Component.onDestruction: BluetoothService.scanners--

    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(Style.fontSize * 0.5)

        VIcon {
            icon: BluetoothService.enabled ? (BluetoothService.connected.length > 0 ? "bluetooth-connected" : "bluetooth") : "bluetooth-off"
            color: Theme.accent
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            VText {
                text: "Bluetooth"
                font.bold: true
            }
            VText {
                Layout.fillWidth: true
                text: !BluetoothService.available ? "No Bluetooth adapter"
                    : !BluetoothService.enabled ? "Off"
                    : BluetoothService.adapter.discovering ? "On · looking for devices" : "On"
                color: Theme.textMuted
                font.pixelSize: Style.fontSize * 0.88
            }
        }
        VToggle {
            visible: BluetoothService.available
            value: BluetoothService.enabled
            onChangedByUser: v => BluetoothService.adapter.enabled = v
        }
    }

    Flickable {
        id: list
        visible: BluetoothService.enabled
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, Style.fontSize * 28)
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        T.ScrollBar.vertical: T.ScrollBar {
            id: scroll
            policy: list.contentHeight > list.height ? T.ScrollBar.AlwaysOn : T.ScrollBar.AlwaysOff
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: Theme.border
            }
        }

        ColumnLayout {
            id: column
            width: list.width - (scroll.visible ? 8 : 0)
            spacing: 2

            Section {
                text: "Connected"
                visible: BluetoothService.connected.length > 0
            }
            Repeater {
                model: BluetoothService.connected
                DeviceRow {}
            }

            Section {
                text: "Paired"
                visible: BluetoothService.paired.length > 0
            }
            Repeater {
                model: BluetoothService.paired
                DeviceRow {}
            }

            Section {
                text: "Nearby"
                visible: BluetoothService.nearby.length > 0
            }
            Repeater {
                model: BluetoothService.nearby
                DeviceRow {}
            }

            VText {
                visible: BluetoothService.nearby.length === 0
                Layout.fillWidth: true
                Layout.topMargin: Math.round(Style.fontSize * 0.4)
                text: "Put a device in pairing mode to see it here."
                color: Theme.textMuted
                font.pixelSize: Style.fontSize * 0.9
                wrapMode: Text.Wrap
            }
        }
    }

    component Section: VText {
        Layout.fillWidth: true
        Layout.topMargin: Math.round(Style.fontSize * 0.5)
        color: Theme.textMuted
        font.pixelSize: Style.fontSize * 0.85
        font.bold: true
    }

    // Click: connect a paired device / pair a nearby one / show buttons for
    // a connected one.
    component DeviceRow: ColumnLayout {
        id: device
        required property BluetoothDevice modelData
        readonly property bool known: modelData.paired || modelData.bonded
        readonly property bool open: root.expanded === modelData.address
        readonly property bool working: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting

        Layout.fillWidth: true
        spacing: 2

        MouseArea {
            id: row
            Layout.fillWidth: true
            implicitHeight: Math.round(Style.fontSize * 2.9)
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (device.working)
                    return;
                if (device.modelData.connected || device.known && device.open)
                    root.expanded = device.open ? "" : device.modelData.address;
                else if (device.known)
                    device.modelData.connect();
                else
                    BluetoothService.pair(device.modelData);
            }

            Rectangle {
                anchors.fill: parent
                radius: Style.radius
                color: device.modelData.connected ? Theme.surface : row.containsMouse ? Qt.alpha(Theme.surface, 0.5) : "transparent"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Math.round(Style.fontSize * 0.6)
                anchors.rightMargin: Math.round(Style.fontSize * 0.3)
                spacing: Math.round(Style.fontSize * 0.7)

                VIcon {
                    icon: BluetoothService.icon(device.modelData)
                    color: device.modelData.connected ? Theme.accent : Theme.text
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    VText {
                        Layout.fillWidth: true
                        text: BluetoothService.displayName(device.modelData)
                        font.bold: device.modelData.connected
                        elide: Text.ElideRight
                    }
                    VText {
                        Layout.fillWidth: true
                        text: {
                            const d = device.modelData;
                            if (d.pairing) return "Pairing...";
                            if (d.state === BluetoothDeviceState.Connecting) return "Connecting...";
                            if (d.state === BluetoothDeviceState.Disconnecting) return "Disconnecting...";
                            if (d.connected) return d.batteryAvailable ? `Connected · battery ${Math.round(d.battery * 100)}%` : "Connected";
                            return device.known ? "Click to connect" : "Click to pair";
                        }
                        color: Theme.textMuted
                        font.pixelSize: Style.fontSize * 0.82
                        elide: Text.ElideRight
                    }
                }
                // Paired but not connected: buttons without connecting first.
                VIconButton {
                    visible: device.known && !device.modelData.connected
                    iconName: "dots"
                    tooltip: "More"
                    size: Math.round(Style.fontSize * 1.9)
                    onClicked: root.expanded = device.open ? "" : device.modelData.address
                }
            }
        }

        RowLayout {
            visible: device.open
            Layout.leftMargin: Math.round(Style.fontSize * 0.6)
            Layout.bottomMargin: Math.round(Style.fontSize * 0.3)

            VButton {
                text: device.modelData.connected ? "Disconnect" : "Connect"
                onClicked: {
                    root.expanded = "";
                    if (device.modelData.connected)
                        device.modelData.disconnect();
                    else
                        device.modelData.connect();
                }
            }
            VButton {
                text: "Forget"
                style: "danger"
                onClicked: {
                    root.expanded = "";
                    device.modelData.forget();
                }
            }
        }
    }
}
