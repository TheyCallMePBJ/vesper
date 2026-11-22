pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// The default Bluetooth adapter and its devices, sorted for display. The
// Bluetooth panel bumps `scanners` while open to discover new devices.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: available && adapter.enabled
    readonly property var devices: adapter ? adapter.devices.values : []

    readonly property var connected: devices.filter(d => d.connected)
    readonly property var paired: devices.filter(d => !d.connected && (d.paired || d.bonded))
    // Discovered, not paired. Unnamed devices (just an address) are hidden.
    readonly property var nearby: devices.filter(d => !d.connected && !d.paired && !d.bonded && hasName(d))
                                         .sort((a, b) => displayName(a).localeCompare(displayName(b)))

    property int scanners: 0
    readonly property bool wantScan: scanners > 0 && enabled

    onWantScanChanged: if (adapter) adapter.discovering = wantScan

    function togglePower() {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }

    function hasName(d) {
        const name = d.name || d.deviceName || "";
        return name !== "" && name.replace(/[-:]/g, "") !== d.address.replace(/[-:]/g, "");
    }

    function displayName(d) {
        return d.name || d.deviceName || d.address;
    }

    // Tabler icon for a BlueZ device icon name.
    function icon(d) {
        const i = d.icon || "";
        if (/headset|headphone/.test(i)) return "headphones";
        if (/audio|speaker/.test(i)) return "device-speaker";
        if (/keyboard/.test(i)) return "keyboard";
        if (/mouse/.test(i)) return "mouse";
        if (/gaming|joystick/.test(i)) return "device-gamepad-2";
        if (/phone/.test(i)) return "device-mobile";
        if (/computer/.test(i)) return "device-laptop";
        if (/watch/.test(i)) return "device-watch";
        return "bluetooth";
    }

    // Pairing also trusts the device, so it can reconnect on its own.
    function pair(d) {
        d.trusted = true;
        d.pair();
    }
}
