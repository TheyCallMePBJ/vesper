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
