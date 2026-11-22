pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Network state and actions through NetworkManager's nmcli: wired and Wi-Fi
// status, Wi-Fi networks, and VPN connections. Refreshes on `nmcli monitor`
// events; Wi-Fi scanning only runs while something asks for it (`scanners`).
Singleton {
    id: root

    // [{ name, type, state, connection }] for ethernet / wifi devices.
    property var devices: []
    // Saved connections: [{ name, uuid, type, device, active }]
    property var connections: []
    // [{ ssid, signal, security, inUse, known }], strongest first.
    property var wifiNetworks: []
    property bool wifiEnabled: false
    // full | limited | portal | none | unknown
    property string connectivity: "unknown"
    property bool available: false
    // Last failed action, shown in the network panel.
    property string lastError: ""
    // SSID / VPN uuid with an action in progress.
    property string busy: ""

    // The network panel bumps this while open, to keep the Wi-Fi list fresh.
    property int scanners: 0

    readonly property var wiredDevice: devices.find(d => d.type === "ethernet" && d.state === "connected") || null
    readonly property var wifiDevice: devices.find(d => d.type === "wifi") || null
    readonly property bool hasWifi: wifiDevice !== null
    readonly property var activeWifi: wifiNetworks.find(n => n.inUse) || null
    readonly property bool wifiConnected: !!wifiDevice && wifiDevice.state === "connected"
    readonly property bool connected: wiredDevice !== null || wifiConnected

    // VPN connections managed by NetworkManager.
    readonly property var vpns: connections.filter(c => c.type === "vpn" || c.type === "wireguard")
    readonly property var activeVpns: vpns.filter(v => v.active)
    // A NetworkManager VPN is connected. Tunnels set up by other software
    // (Tailscale, wg-quick, ...) don't count: they're often always on.
    readonly property bool vpnActive: activeVpns.length > 0
    // Those tunnels, listed in the network panel but not controllable.
    property var externalTunnels: []

    // Icon for the current connection.
    readonly property string icon: {
        if (!available)
            return "network-off";
        if (wiredDevice)
            return "network";
        if (wifiConnected)
            return wifiIcon(activeWifi ? activeWifi.signal : 60);
        return wifiEnabled ? "wifi-off" : "network-off";
    }
    // Tabler's Wi-Fi icons: a dot plus 0-3 arcs by signal strength.
    function wifiIcon(signal) {
        return signal >= 70 ? "wifi" : signal >= 45 ? "wifi-2" : signal >= 20 ? "wifi-1" : "wifi-0";
    }

    readonly property string label: wiredDevice ? (wiredDevice.connection || "Wired")
                                  : wifiConnected ? (wifiDevice.connection || "Wi-Fi") : "Disconnected"

    // ---- Actions -----------------------------------------------------------

    function setWifiEnabled(on) {
        run(["nmcli", "radio", "wifi", on ? "on" : "off"], "");
        wifiEnabled = on;
    }

    function rescan() {
        if (wifiEnabled)
            run(["nmcli", "device", "wifi", "rescan"], "");
    }

    // Saved networks connect directly; new secured ones need the password.
    function connectWifi(ssid, password) {
        lastError = "";
        busy = ssid;
        const cmd = ["nmcli", "--wait", "30"].concat(password ? ["--ask"] : [], ["device", "wifi", "connect", ssid]);
        // The password goes through stdin, so it never appears in the process list.
        run(cmd, ssid, password ? password + "\n" : "");
    }

    function disconnectWifi() {
        if (wifiDevice)
            run(["nmcli", "device", "disconnect", wifiDevice.name], "");
    }

    function forgetWifi(ssid) {
        const saved = connections.find(c => c.type === "802-11-wireless" && c.name === ssid);
        if (saved)
            run(["nmcli", "connection", "delete", "uuid", saved.uuid], "");
    }

    function setVpn(uuid, on) {
        lastError = "";
        busy = uuid;
        run(["nmcli", "--wait", "30", "connection", on ? "up" : "down", "uuid", uuid], uuid);
    }

    function refresh() {
        refreshTimer.restart();
    }

    // ---- Running nmcli ------------------------------------------------------

    // Splits nmcli -t -e yes output on unescaped colons.
    function fields(line) {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (c === "\\" && i + 1 < line.length) {
                cur += line[++i];
            } else if (c === ":") {
                out.push(cur);
                cur = "";
            } else {
                cur += c;
            }
        }
        out.push(cur);
        return out;
    }

    function lines(text) {
        return text.split("\n").filter(l => l.trim() !== "");
    }

    // One action at a time, each with its own process.
    function run(command, busyKey, input) {
        const proc = actionComponent.createObject(root, { command, busyKey, input: input || "" });
        proc.running = true;
    }

    Component {
        id: actionComponent

        Process {
            id: action
            property string busyKey
            property string input
            stdinEnabled: input !== ""
            onStarted: if (input !== "") write(input)
            stderr: StdioCollector { id: errors }
            stdout: StdioCollector { id: output }
            onExited: code => {
                if (code !== 0) {
                    const message = (errors.text || output.text).trim().replace(/^Error:\s*/, "");
                    root.lastError = message || `nmcli failed (exit code ${code})`;
                    Logger.w("Network", `${command.join(" ")}: ${root.lastError}`);
                }
                if (root.busy === busyKey)
                    root.busy = "";
                root.refresh();
                destroy();
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 200
        onTriggered: {
            devicesProc.running = true;
            connectionsProc.running = true;
            radioProc.running = true;
            connectivityProc.running = true;
            if ((root.scanners > 0 || root.wifiConnected) && root.wifiEnabled)
                wifiProc.running = true;
        }
    }

    Process {
        id: devicesProc
        command: ["nmcli", "-t", "-e", "yes", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                const devices = [];
                const tunnels = [];
                for (const line of root.lines(text)) {
                    const [name, type, state, connection] = root.fields(line);
                    if (type === "ethernet" || type === "wifi") {
                        if (state !== "unmanaged")
                            devices.push({ name, type, state: state.split(" ")[0], connection });
                    } else if ((type === "tun" || type === "wireguard") && state.startsWith("connected (externally)")) {
                        tunnels.push({ name: connection || name, device: name });
                    }
                }
                root.devices = devices;
                root.externalTunnels = tunnels;
            }
        }
        onExited: code => root.available = code === 0
    }

    Process {
        id: connectionsProc
        command: ["nmcli", "-t", "-e", "yes", "-f", "NAME,UUID,TYPE,DEVICE,ACTIVE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.connections = root.lines(text).map(line => {
                    const [name, uuid, type, device, active] = root.fields(line);
                    return { name, uuid, type, device, active: active === "yes" };
                });
            }
        }
    }

    Process {
        id: radioProc
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
    }

    Process {
        id: connectivityProc
        command: ["nmcli", "-t", "networking", "connectivity"]
        stdout: StdioCollector {
            onStreamFinished: root.connectivity = text.trim() || "unknown"
        }
    }

    Process {
        id: wifiProc
        // --rescan no: use NetworkManager's cached results; rescan() asks for fresh ones.
        command: ["nmcli", "-t", "-e", "yes", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const known = new Set(root.connections.filter(c => c.type === "802-11-wireless").map(c => c.name));
                const bySsid = {};
                for (const line of root.lines(text)) {
                    const [inUse, ssid, signal, security] = root.fields(line);
                    if (!ssid)
                        continue;
                    const net = { ssid, signal: Number(signal) || 0, security: security === "--" ? "" : security, inUse: inUse === "*", known: known.has(ssid) };
                    // One entry per SSID: the one in use, else the strongest.
                    const prev = bySsid[ssid];
                    if (!prev || net.inUse || (!prev.inUse && net.signal > prev.signal))
                        bySsid[ssid] = net;
                }
                root.wifiNetworks = Object.values(bySsid).sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal));
            }
        }
    }

    // NetworkManager prints a line for every change.
    Process {
        id: monitor
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root.refresh()
        }
        onExited: monitorRestart.restart()
    }

    // If NetworkManager restarts (or isn't running yet), try again later.
    Timer {
        id: monitorRestart
        interval: 10000
        onTriggered: monitor.running = true
    }

    // While the panel is open: rescan now and then; the list refreshes on its own.
    Timer {
        interval: 10000
        repeat: true
        triggeredOnStart: true
        running: root.scanners > 0 && root.wifiEnabled
        onTriggered: {
            root.rescan();
            wifiProc.running = true;
        }
    }

    // Signal strength of the connected network, for the bar icon.
    Timer {
        interval: 30000
        repeat: true
        running: root.wifiConnected && root.scanners === 0
        onTriggered: wifiProc.running = true
    }

    Component.onCompleted: refresh()
}
