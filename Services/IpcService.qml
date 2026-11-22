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
        // Open on a tab: bar, widgets, appearance, notifications, general.
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
        target: "volume"

        function up(): void { AudioService.changeVolume(1); }
        function down(): void { AudioService.changeVolume(-1); }
        function toggleMute(): void { AudioService.toggleMute(); }
        // Percentage 0-100.
        function set(percent: int): void { AudioService.setVolume(percent / 100); }
        function get(): int { return Math.round(AudioService.volume * 100); }
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
        function next(): void { MediaService.next(); }
        function previous(): void { MediaService.previous(); }
    }
}
