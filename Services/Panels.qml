pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Which panels are open, and on which screen. Panels are created lazily in
// shell.qml from these properties.
Singleton {
    id: root

    property bool settingsOpen: false
    property ShellScreen settingsScreen: null

    property bool sessionOpen: false
    property ShellScreen sessionScreen: null

    // The screen with Hyprland's focused monitor, or the first screen.
    function focusedScreen() {
        const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++)
            if (screens[i].name === name)
                return screens[i];
        return screens.length > 0 ? screens[0] : null;
    }

    function openSettings(screen) {
        settingsScreen = screen || focusedScreen();
        settingsOpen = true;
    }

    function closeSettings() {
        settingsOpen = false;
    }

    function toggleSettings(screen) {
        if (settingsOpen)
            closeSettings();
        else
            openSettings(screen);
    }

    function openSession(screen) {
        sessionScreen = screen || focusedScreen();
        sessionOpen = true;
    }

    function closeSession() {
        sessionOpen = false;
    }

    function toggleSession(screen) {
        if (sessionOpen)
            closeSession();
        else
            openSession(screen);
    }
}
