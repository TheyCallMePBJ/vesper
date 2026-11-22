pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Screen brightness for every screen that supports it: laptop backlights and,
// with ddcutil, external monitors. Use forScreen(screen) to get a
// BrightnessMonitor with `value` (0..1), set() and change().
Singleton {
    id: root

    // Output name -> I2C bus number, from `ddcutil detect`.
    property var ddcBuses: ({})
    // Backlight device names in /sys/class/backlight.
    property var backlights: []

    readonly property var monitors: monitorVariants.instances
    readonly property var available: monitors.filter(m => m.available)

    // Emitted for changes made through Vesper (for the OSD).
    signal changedByUser(var monitor)

    function forScreen(screen) {
        return screen ? monitors.find(m => m.name === screen.name) || null : null;
    }

    function set(monitor, v) {
        if (!monitor)
            return;
        monitor.set(v);
        changedByUser(monitor);
    }

    function change(monitor, direction) {
        if (!monitor || !monitor.available)
            return;
        monitor.change(direction);
        changedByUser(monitor);
    }

    // Re-detect monitors (e.g. after plugging one in).
    function detect() {
        backlightProc.running = true;
        if (Settings.brightness.ddc)
            ddcDetect.running = true;
        else
            ddcBuses = {};
    }

    function refreshAll() {
        for (const m of monitors)
            m.refresh();
    }

    Component.onCompleted: detect()

    Connections {
        target: Settings
        function onBrightnessChanged() {
            if (Settings.brightness.ddc && Object.keys(root.ddcBuses).length === 0)
                ddcDetect.running = true;
        }
    }

    Connections {
        target: Quickshell
        function onScreensChanged() { redetectTimer.restart(); }
    }

    // Monitors take a moment to answer DDC after being plugged in.
    Timer {
        id: redetectTimer
        interval: 3000
        onTriggered: root.detect()
    }

    Variants {
        id: monitorVariants
        model: Quickshell.screens
        BrightnessMonitor {}
    }

    Process {
        id: ddcDetect
        command: ["ddcutil", "detect", "--brief"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Blocks of "I2C bus: /dev/i2c-N" ... "DRM connector: cardX-DP-4"
                const buses = {};
                for (const block of text.split(/\n\s*\n/)) {
                    const bus = block.match(/I2C bus:\s*\/dev\/i2c-(\d+)/);
                    const connector = block.match(/DRM connector:\s*card\d+-(\S+)/);
                    if (bus && connector && !/Invalid display/.test(block))
                        buses[connector[1]] = bus[1];
                }
                root.ddcBuses = buses;
            }
        }
        onExited: code => {
            if (code !== 0)
                Logger.w("Brightness", "ddcutil detect failed; is ddcutil installed and the i2c-dev module loaded?");
        }
    }

    Process {
        id: backlightProc
        command: ["sh", "-c", "ls /sys/class/backlight 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: root.backlights = text.split("\n").filter(l => l.trim() !== "")
        }
    }
}
