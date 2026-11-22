pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Warmer screen colours through hyprsunset, which Vesper runs while night
// light is on (and which stops with Vesper). `enabled` is the user's switch;
// with a schedule it only applies between start and end.
Singleton {
    id: root

    property bool installed: false
    readonly property bool enabled: Settings.nightLight.enabled === true
    readonly property bool scheduled: Settings.nightLight.schedule === true
    readonly property int temperature: Math.max(1000, Math.min(6500, Settings.nightLight.temperature || 4000))

    readonly property bool inWindow: {
        const now = clock.hours * 60 + clock.minutes;
        const start = toMinutes(Settings.nightLight.start, 18 * 60 + 30);
        const end = toMinutes(Settings.nightLight.end, 6 * 60 + 30);
        return start <= end ? (now >= start && now < end) : (now >= start || now < end);
    }
    // Whether the screen is warmed right now.
    readonly property bool active: installed && enabled && (!scheduled || inWindow)

    function setEnabled(on) {
        Settings.set("nightLight.enabled", on);
    }
    function toggle() {
        setEnabled(!enabled);
    }

    function toMinutes(text, fallback) {
        const m = String(text || "").match(/^(\d{1,2}):(\d{2})$/);
        return m ? (Number(m[1]) % 24) * 60 + Number(m[2]) % 60 : fallback;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: root.scheduled
    }

    Process {
        id: check
        running: true
        command: ["sh", "-c", "command -v hyprsunset"]
        onExited: code => root.installed = code === 0
    }

    Process {
        id: sunset
        running: root.active
        command: ["hyprsunset", "-t", String(root.temperature)]
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "" && sunset.running === false && root.active) Logger.w("NightLight", "hyprsunset: " + text.trim())
        }
    }

    // A new temperature while it's on: tell the running hyprsunset.
    onTemperatureChanged: {
        if (sunset.running)
            Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(temperature)]);
    }
}
