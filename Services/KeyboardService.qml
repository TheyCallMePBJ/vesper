pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons

// Keyboard layout (from Hyprland) and Caps/Num/Scroll Lock state (from the
// keyboard LEDs in /sys/class/leds, since Hyprland has no event for them).
Singleton {
    id: root

    property string layoutName: ""   // e.g. "English (US)"
    property string layoutCode: ""   // e.g. "us"
    property int layoutCount: 1

    property bool capsLock: false
    property bool numLock: false
    property bool scrollLock: false

    // LockKeys widgets register here so LEDs are only polled while needed.
    property int lockKeyWatchers: 0

    function nextLayout() {
        Quickshell.execDetached(["hyprctl", "switchxkblayout", "main", "next"]);
    }

    // ---- Layout -------------------------------------------------------------

    function parseDevices(text) {
        let data;
        try {
            data = JSON.parse(text);
        } catch (err) {
            Logger.w("Keyboard", "Could not parse hyprctl devices output");
            return;
        }
        const keyboards = data.keyboards || [];
        const kb = keyboards.find(k => k.main) || keyboards[0];
        if (!kb)
            return;
        const layouts = String(kb.layout || "").split(",").filter(l => l !== "");
        const index = kb.active_layout_index !== undefined ? kb.active_layout_index : 0;
        layoutName = kb.active_keymap || "";
        layoutCode = layouts[index] || layouts[0] || "";
        layoutCount = Math.max(1, layouts.length);
    }

    Process {
        id: devicesProc
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.parseDevices(text)
        }
    }

    Component.onCompleted: devicesProc.running = true

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout" || event.name === "configreloaded")
                devicesProc.running = true;
        }
    }

    // ---- Lock keys ------------------------------------------------------------

    property var ledDirs: []
    property var ledState: ({})

    function updateLocks() {
        const on = kind => Object.keys(ledState).some(dir => dir.endsWith("::" + kind) && ledState[dir]);
        capsLock = on("capslock");
        numLock = on("numlock");
        scrollLock = on("scrolllock");
    }

    // Finds LED folders; re-run now and then to catch keyboards plugged in later.
    Process {
        id: ledScan
        command: ["sh", "-c", "for d in /sys/class/leds/*::capslock /sys/class/leds/*::numlock /sys/class/leds/*::scrolllock; do [ -e \"$d/brightness\" ] && echo \"$d\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const dirs = text.split("\n").filter(l => l !== "");
                if (JSON.stringify(dirs) !== JSON.stringify(root.ledDirs)) {
                    root.ledDirs = dirs;
                    root.ledState = {};
                }
            }
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: root.lockKeyWatchers > 0
        triggeredOnStart: true
        onTriggered: ledScan.running = true
    }

    Instantiator {
        id: ledFiles
        model: root.lockKeyWatchers > 0 ? root.ledDirs : []

        FileView {
            required property string modelData
            path: modelData + "/brightness"
            blockLoading: true
            printErrors: false
            onLoaded: {
                const state = Object.assign({}, root.ledState);
                state[modelData] = text().trim() !== "0";
                root.ledState = state;
                root.updateLocks();
            }
        }
    }

    Timer {
        interval: 300
        repeat: true
        running: root.lockKeyWatchers > 0 && root.ledDirs.length > 0
        onTriggered: {
            for (let i = 0; i < ledFiles.count; i++)
                ledFiles.objectAt(i).reload();
        }
    }
}
