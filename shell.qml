//@ pragma UseQApplication
import QtQuick
import Quickshell
import qs.Commons
import qs.Services
import qs.Modules.Bar
import qs.Modules.Settings
import qs.Modules.SessionMenu
import qs.Modules.Panels
import qs.Modules.OSD
import qs.Modules.Notifications

ShellRoot {
    // One bar per screen, limited to bar.monitors if that list isn't empty.
    Variants {
        model: {
            const wanted = Settings.bar.monitors || [];
            return Quickshell.screens.filter(s => wanted.length === 0 || wanted.includes(s.name));
        }

        Bar {}
    }

    // Only exists while open.
    LazyLoader {
        active: Panels.settingsOpen
        SettingsWindow {}
    }

    LazyLoader {
        active: Panels.sessionOpen
        SessionMenu {}
    }

    // Bar panels: at most one is open at a time.
    LazyLoader {
        active: Panels.panel === "calendar"
        CalendarPanel {}
    }

    LazyLoader {
        active: Panels.panel === "audio"
        AudioPanel {}
    }

    LazyLoader {
        active: Panels.panel === "notifications"
        NotificationHistoryPanel {}
    }

    LazyLoader {
        active: Panels.panel === "controlCenter"
        ControlCenterPanel {}
    }

    LazyLoader {
        active: Panels.panel === "network"
        NetworkPanel {}
    }

    LazyLoader {
        active: Panels.panel === "bluetooth"
        BluetoothPanel {}
    }

    Osd {}

    NotificationPopups {}

    IpcService {}
}
