import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Brightness of one screen: a laptop backlight (via brightnessctl) or an
// external monitor over DDC/CI (via ddcutil). Created per screen by
// BrightnessService.
Scope {
    id: root

    required property ShellScreen modelData
    readonly property string name: modelData.name

    // Built-in panels use the backlight; everything else DDC.
    readonly property bool internal: /^(eDP|LVDS|DSI)/.test(name)
    readonly property string backlight: internal && BrightnessService.backlights.length > 0 ? BrightnessService.backlights[0] : ""
    readonly property string bus: !internal && Settings.brightness.ddc ? (BrightnessService.ddcBuses[name] || "") : ""
    readonly property string method: backlight !== "" ? "backlight" : bus !== "" ? "ddc" : "none"

    // 0..1. Set by set() straight away; the hardware catches up.
    property real value: 0
    property int maxRaw: 100
    property bool known: false
    readonly property bool available: method !== "none" && known

    function set(v) {
        if (method === "none")
            return;
        value = Math.max(0, Math.min(1, v));
        if (method === "backlight") {
            Quickshell.execDetached(["brightnessctl", "--quiet", "-d", backlight, "set", Math.round(value * 100) + "%"]);
            return;
        }
        // ddcutil is slow; send only the latest value, one write at a time.
        ddcWriteTimer.restart();
    }

    function change(direction) {
        const step = Math.max(1, Settings.brightness.step || 5) / 100;
        set(Math.round((value + direction * step) * 100) / 100);
    }

    // Re-read from the hardware (e.g. after using the monitor's buttons).
    function refresh() {
        if (method === "ddc" && !ddcWrite.running && !ddcWriteTimer.running) {
            // Set here, not bound: this runs from onMethodChanged, before a
            // binding on `bus` would have updated.
            ddcRead.command = ["ddcutil", "--bus", bus, "getvcp", "10", "--brief"];
            ddcRead.running = true;
        }
        else if (method === "backlight")
            backlightFile.reload();
    }

    onMethodChanged: {
        known = false;
        refresh();
    }
    Component.onCompleted: refresh()

    // ---- DDC ---------------------------------------------------------------

    Process {
        id: ddcRead
        stdout: StdioCollector {
            // "VCP 10 C <current> <max>"
            onStreamFinished: {
                const m = text.match(/VCP 10 C (\d+) (\d+)/);
                if (m && Number(m[2]) > 0) {
                    root.maxRaw = Number(m[2]);
                    root.value = Number(m[1]) / root.maxRaw;
                    root.known = true;
                } else {
                    Logger.w("Brightness", `ddcutil could not read the brightness of ${root.name}`);
                }
            }
        }
    }

    Timer {
        id: ddcWriteTimer
        interval: 120
        onTriggered: {
            if (ddcWrite.running) {
                restart();
                return;
            }
            ddcWrite.command = ["ddcutil", "--bus", root.bus, "--noverify", "setvcp", "10", String(Math.round(root.value * root.maxRaw))];
            ddcWrite.running = true;
        }
    }

    Process {
        id: ddcWrite
    }

    // ---- Backlight ---------------------------------------------------------

    FileView {
        id: backlightFile
        path: root.backlight !== "" ? `/sys/class/backlight/${root.backlight}/brightness` : ""
        onLoaded: {
            const raw = parseInt(text());
            if (!isNaN(raw) && root.maxRaw > 0) {
                root.value = raw / root.maxRaw;
                root.known = true;
            }
        }
    }

    FileView {
        path: root.backlight !== "" ? `/sys/class/backlight/${root.backlight}/max_brightness` : ""
        onLoaded: {
            root.maxRaw = parseInt(text()) || 100;
            backlightFile.reload();
        }
    }

    // sysfs doesn't send change events, so follow brightness keys by polling.
    Timer {
        interval: 1000
        repeat: true
        running: root.method === "backlight"
        onTriggered: backlightFile.reload()
    }
}
