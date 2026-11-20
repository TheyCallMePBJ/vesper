//@ pragma UseQApplication
import QtQuick
import Quickshell
import qs.Commons
import qs.Services
import qs.Modules.Bar
import qs.Modules.Settings
import qs.Modules.SessionMenu

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

    IpcService {}
}
