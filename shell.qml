//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Modules.Bar
import qs.Modules.Settings
import qs.Modules.SessionMenu
import qs.Modules.Panels
import qs.Modules.OSD
import qs.Modules.Notifications
import qs.Modules.Launcher
import qs.Modules.Wallpaper

ShellRoot {
    // Wallpaper, on the background layer.
    Variants {
        model: WallpaperService.enabled ? Quickshell.screens : []
        Wallpaper {}
    }

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

    LazyLoader {
        active: Panels.launcherOpen
        Launcher {}
    }

    LazyLoader {
        active: Panels.wallpaperOpen
        WallpaperPicker {}
    }

    // While a bar panel is open, a click on any other screen closes it (the
    // panel itself only covers its own screen). Bars there still get clicks.
    Variants {
        model: Panels.panel !== "" ? Quickshell.screens.filter(s => s !== Panels.panelScreen) : []

        PanelWindow {
            required property ShellScreen modelData
            screen: modelData
            WlrLayershell.namespace: "vesper-panel-dismiss"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Normal
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onPressed: Panels.closePanel()
            }
        }
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
