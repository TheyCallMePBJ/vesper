import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// IPC targets, called as: qs -c vesper ipc call <target> <function>
// e.g. qs -c vesper ipc call volume up
// Instantiated once in shell.qml.
Scope {
    IpcHandler {
        target: "settings"

        // Open/close the settings window on the focused monitor.
        function toggle(): void { Panels.toggleSettings(null); }
        function open(): void { Panels.openSettings(null); }
        function close(): void { Panels.closeSettings(); }
        // Open on a tab: bar, widgets, appearance, notifications, system, launcher, wallpaper, general.
        function openTab(tab: string): void { Panels.openSettingsTab(tab, null); }
        // Re-read settings.json.
        function reload(): void { Settings.reload(); }
    }

    IpcHandler {
        target: "session"

        function toggle(): void { Panels.toggleSession(null); }
        function open(): void { Panels.openSession(null); }
        function close(): void { Panels.closeSession(); }
    }

    IpcHandler {
        target: "launcher"

        // The app launcher / calculator, on the focused monitor.
        function toggle(): void { Panels.toggleLauncher(null); }
        function open(): void { Panels.openLauncher(null); }
        function close(): void { Panels.launcherOpen = false; }
        // Open with this text already typed, e.g. "=" or "100 usd to ".
        function search(text: string): void { Panels.openLauncher(null, text); }
    }

    IpcHandler {
        target: "wallpaper"

        // The wallpaper picker, on the focused monitor.
        function toggle(): void { Panels.toggleWallpaper(null); }
        function open(): void { Panels.openWallpaper(null); }
        function close(): void { Panels.wallpaperOpen = false; }
        // Set an image (full path) on every monitor, or on one: set "<path>" "DP-1".
        function set(path: string, monitor: string): void { WallpaperService.set(path, monitor); }
        // A random image from the wallpaper folder.
        function random(): void { WallpaperService.random(""); }
        // Stop drawing a wallpaper.
        function clear(): void { WallpaperService.clear(); }
    }

    IpcHandler {
        target: "calendar"

        // Opens next to the Clock widget on the focused monitor, if there is one.
        function toggle(): void { Panels.togglePanel("calendar", null); }
        function open(): void { Panels.openPanel("calendar", null); }
        function close(): void { if (Panels.panel === "calendar") Panels.closePanel(); }
    }

    IpcHandler {
        target: "audio"

        // The audio panel (devices and app volumes).
        function toggle(): void { Panels.togglePanel("audio", null); }
        function open(): void { Panels.openPanel("audio", null); }
        function close(): void { if (Panels.panel === "audio") Panels.closePanel(); }
    }

    IpcHandler {
        target: "notifications"

        // The history panel.
        function toggle(): void { Panels.togglePanel("notifications", null); }
        function open(): void { Panels.openPanel("notifications", null); }
        function close(): void { if (Panels.panel === "notifications") Panels.closePanel(); }
        function toggleDnd(): void { NotificationService.setDoNotDisturb(!NotificationService.doNotDisturb); }
        function setDnd(on: bool): void { NotificationService.setDoNotDisturb(on); }
        function clear(): void { NotificationService.clearHistory(); }
        // Hide all popups (they stay in the history).
        function dismissPopups(): void { NotificationService.hideAllPopups(); }
    }

    IpcHandler {
        target: "controlCenter"

        function toggle(): void { Panels.togglePanel("controlCenter", null); }
        function open(): void { Panels.openPanel("controlCenter", null); }
        function close(): void { if (Panels.panel === "controlCenter") Panels.closePanel(); }
    }

    IpcHandler {
        target: "network"

        function toggle(): void { Panels.togglePanel("network", null); }
        function open(): void { Panels.openPanel("network", null); }
        function close(): void { if (Panels.panel === "network") Panels.closePanel(); }
        function toggleWifi(): void { NetworkService.setWifiEnabled(!NetworkService.wifiEnabled); }
    }

    IpcHandler {
        target: "bluetooth"

        function toggle(): void { Panels.togglePanel("bluetooth", null); }
        function open(): void { Panels.openPanel("bluetooth", null); }
        function close(): void { if (Panels.panel === "bluetooth") Panels.closePanel(); }
        function togglePower(): void { BluetoothService.togglePower(); }
    }

    IpcHandler {
        target: "volume"

        function up(): void { AudioService.changeVolume(1); }
        function down(): void { AudioService.changeVolume(-1); }
        function toggleMute(): void { AudioService.toggleMute(); }
        // Percentage 0-100.
        function set(percent: int): void { AudioService.setVolume(percent / 100); }
        function get(): int { return Math.round(AudioService.volume * 100); }
    }

    IpcHandler {
        target: "brightness"

        // The focused monitor's brightness.
        function up(): void { BrightnessService.change(BrightnessService.forScreen(Panels.focusedScreen()), 1); }
        function down(): void { BrightnessService.change(BrightnessService.forScreen(Panels.focusedScreen()), -1); }
        // Percentage 0-100.
        function set(percent: int): void { BrightnessService.set(BrightnessService.forScreen(Panels.focusedScreen()), percent / 100); }
        function get(): int {
            const m = BrightnessService.forScreen(Panels.focusedScreen());
            return m && m.available ? Math.round(m.value * 100) : -1;
        }
        // Every monitor as "name: percent" lines.
        function list(): string {
            return BrightnessService.monitors.map(m => `${m.name}: ${m.available ? Math.round(m.value * 100) + "%" : "unavailable (" + m.method + ")"}`).join("\n");
        }
        // Re-read levels from the monitors (after using their own buttons).
        function refresh(): void { BrightnessService.refreshAll(); }
        // The brightness panel, next to the bar's brightness widget.
        function toggle(): void { Panels.togglePanel("brightness", null); }
        function open(): void { Panels.openPanel("brightness", null); }
        function close(): void { if (Panels.panel === "brightness") Panels.closePanel(); }
    }

    IpcHandler {
        target: "nightLight"

        function toggle(): void { NightLightService.toggle(); }
        function enable(): void { NightLightService.setEnabled(true); }
        function disable(): void { NightLightService.setEnabled(false); }
        function isActive(): bool { return NightLightService.active; }
    }

    IpcHandler {
        target: "keepAwake"

        function toggle(): void { KeepAwakeService.toggle(); }
        function enable(): void { KeepAwakeService.enabled = true; }
        function disable(): void { KeepAwakeService.enabled = false; }
        function isEnabled(): bool { return KeepAwakeService.enabled; }
    }

    IpcHandler {
        target: "mic"

        function up(): void { AudioService.changeMicVolume(1); }
        function down(): void { AudioService.changeMicVolume(-1); }
        function toggleMute(): void { AudioService.toggleMicMute(); }
    }

    IpcHandler {
        target: "media"

        function playPause(): void { MediaService.togglePlaying(); }
        // Pause everything that's playing (e.g. before locking).
        function pause(): void { MediaService.pauseAll(); }
        function play(): void { MediaService.play(); }
        function next(): void { MediaService.next(); }
        function previous(): void { MediaService.previous(); }
    }
}
