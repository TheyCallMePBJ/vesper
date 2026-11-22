pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// CPU, memory, temperatures, GPU (AMD via sysfs, NVIDIA via nvidia-smi), disk
// and network usage. Only polls while something uses it: widgets bump
// `users` on creation and drop it on destruction.
Singleton {
    id: root

    property int users: 0
    readonly property bool running: users > 0
    readonly property real interval: Math.max(1, Settings.systemMonitor.interval || 2)

    // Percentages are 0..100, temperatures °C, rates bytes/s. -1 = unknown.
    property real cpuUsage: -1
    property real cpuTemp: -1
    property real memUsed: 0
    property real memTotal: 0
    readonly property real memUsage: memTotal > 0 ? memUsed / memTotal * 100 : -1
    property real gpuUsage: -1
    property real gpuTemp: -1
    property real diskUsed: 0
    property real diskTotal: 0
    readonly property real diskUsage: diskTotal > 0 ? diskUsed / diskTotal * 100 : -1
    property real netDown: 0
    property real netUp: 0

    // Found once at startup.
    property string cpuTempFile: ""
    property string gpuBusyFile: ""
    property string gpuTempFile: ""
    property bool hasNvidia: false

    // "warning" / "critical" / "" for colouring.
    function usageLevel(percent) {
        const s = Settings.systemMonitor;
        return percent >= s.criticalPercent ? "critical" : percent >= s.warningPercent ? "warning" : "";
    }
    function tempLevel(celsius) {
        const s = Settings.systemMonitor;
        return celsius >= s.criticalTemp ? "critical" : celsius >= s.warningTemp ? "warning" : "";
    }

    function formatBytes(bytes, perSecond) {
        const units = ["B", "K", "M", "G", "T"];
        let i = 0;
        while (bytes >= 1000 && i < units.length - 1) {
            bytes /= 1024;
            i++;
        }
        const n = bytes >= 100 || i === 0 ? Math.round(bytes) : bytes.toFixed(1);
        return n + units[i] + (perSecond ? "/s" : "");
    }

    // ---- Discovery ---------------------------------------------------------

    Process {
        running: true
        // CPU: coretemp (Intel) / k10temp / zenpower (AMD). GPU: amdgpu busy % and edge temp.
        command: ["sh", "-c", `
            for d in /sys/class/hwmon/hwmon*; do
                case "$(cat $d/name 2>/dev/null)" in
                    coretemp|k10temp|zenpower) echo "cpu $d/temp1_input" ;;
                    amdgpu) echo "gputemp $d/temp1_input" ;;
                esac
            done
            for f in /sys/class/drm/card*/device/gpu_busy_percent; do [ -r "$f" ] && echo "gpubusy $f"; done
            command -v nvidia-smi >/dev/null && echo "nvidia yes"
            true`]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.split("\n")) {
                    const [key, value] = line.split(" ");
                    if (key === "cpu" && !root.cpuTempFile) root.cpuTempFile = value;
                    else if (key === "gputemp" && !root.gpuTempFile) root.gpuTempFile = value;
                    else if (key === "gpubusy" && !root.gpuBusyFile) root.gpuBusyFile = value;
                    else if (key === "nvidia") root.hasNvidia = true;
                }
            }
        }
    }

    // ---- Polling -----------------------------------------------------------

    Timer {
        interval: root.interval * 1000
        running: root.running
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            netdev.reload();
            if (root.cpuTempFile) cpuTempView.reload();
            if (root.gpuBusyFile) gpuBusyView.reload();
            if (root.gpuTempFile) gpuTempView.reload();
            if (root.hasNvidia && !root.gpuBusyFile && !nvidia.running) nvidia.running = true;
        }
    }

    // Disk usage changes slowly.
    Timer {
        interval: 30000
        running: root.running
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            df.command = ["df", "-B1", "--output=used,size", Settings.systemMonitor.diskPath || "/"];
            df.running = true;
        }
    }

    property var lastCpu: null
    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + (f[4] || 0);
            const total = f.reduce((a, b) => a + b, 0);
            if (root.lastCpu && total > root.lastCpu.total)
                root.cpuUsage = Math.round((1 - (idle - root.lastCpu.idle) / (total - root.lastCpu.total)) * 100);
            root.lastCpu = { idle, total };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const kb = key => {
                const m = text().match(new RegExp("^" + key + ":\\s+(\\d+)", "m"));
                return m ? Number(m[1]) * 1024 : 0;
            };
            root.memTotal = kb("MemTotal");
            root.memUsed = root.memTotal - kb("MemAvailable");
        }
    }

    property var lastNet: null
    FileView {
        id: netdev
        path: "/proc/net/dev"
        onLoaded: {
            let rx = 0, tx = 0;
            for (const line of text().split("\n").slice(2)) {
                const m = line.match(/^\s*([^:]+):\s*(.*)$/);
                // Physical traffic only: skip loopback and virtual interfaces,
                // whose traffic is also counted on the real one.
                if (!m || /^(lo|veth|docker|br-|virbr|tun|tap|tailscale|wg)/.test(m[1]))
                    continue;
                const f = m[2].trim().split(/\s+/).map(Number);
                rx += f[0];
                tx += f[8];
            }
            const now = Date.now();
            if (root.lastNet && now > root.lastNet.time) {
                const seconds = (now - root.lastNet.time) / 1000;
                root.netDown = Math.max(0, (rx - root.lastNet.rx) / seconds);
                root.netUp = Math.max(0, (tx - root.lastNet.tx) / seconds);
            }
            root.lastNet = { rx, tx, time: now };
        }
    }

    FileView {
        id: cpuTempView
        path: root.cpuTempFile
        onLoaded: root.cpuTemp = Math.round(parseInt(text()) / 1000)
    }

    FileView {
        id: gpuBusyView
        path: root.gpuBusyFile
        onLoaded: root.gpuUsage = parseInt(text())
    }

    FileView {
        id: gpuTempView
        path: root.gpuTempFile
        onLoaded: root.gpuTemp = Math.round(parseInt(text()) / 1000)
    }

    Process {
        id: nvidia
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [usage, temp] = text.split("\n")[0].split(",").map(v => parseInt(v));
                if (!isNaN(usage)) root.gpuUsage = usage;
                if (!isNaN(temp)) root.gpuTemp = temp;
            }
        }
    }

    Process {
        id: df
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split("\n").pop().trim().split(/\s+/).map(Number);
                if (f.length === 2 && f[1] > 0) {
                    root.diskUsed = f[0];
                    root.diskTotal = f[1];
                }
            }
        }
    }
}
