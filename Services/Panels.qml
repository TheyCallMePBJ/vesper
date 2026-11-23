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
    // Tab to show when the settings window opens; "" keeps the current one.
    property string settingsTab: ""

    property bool sessionOpen: false
    property ShellScreen sessionScreen: null

    property bool launcherOpen: false
    property ShellScreen launcherScreen: null
    // Text the launcher starts with (IPC "launcher search").
    property string launcherQuery: ""

    property bool wallpaperOpen: false
    property ShellScreen wallpaperScreen: null

    // The one bar panel that's open ("calendar", "audio", "notifications",
    // "controlCenter"), or "". It opens next to `panelAnchor`: the widget
    // that opened it, or one registered for it on that screen's bar.
    property string panel: ""
    property ShellScreen panelScreen: null
    property Item panelAnchor: null

    // Widgets that can open a panel register here, so IPC can open the panel
    // next to them: [{ name, item }].
    property var anchors: []

    function registerAnchor(name, item) {
        anchors = anchors.concat([{ name, item }]);
    }
    function unregisterAnchor(item) {
        anchors = anchors.filter(a => a.item !== item);
    }

    function findAnchor(name, screen) {
        const match = anchors.find(a => a.name === name && a.item.screen === screen && a.item.visible);
        return match ? match.item : null;
    }

    // `anchorItem` is a BarWidget (it has `screen`), or null for IPC.
    // Without an anchor, the panel opens on `onScreen` (or the focused screen),
    // next to the widget registered for it there if any.
    function openPanel(name, anchorItem, onScreen) {
        const screen = anchorItem && anchorItem.screen ? anchorItem.screen : (onScreen || focusedScreen());
        // Moving to another screen recreates the panel there.
        if (panel !== "" && panelScreen !== screen)
            panel = "";
        panelAnchor = anchorItem || findAnchor(name, screen);
        panelScreen = screen;
        panel = name;
    }

    function closePanel() {
        panel = "";
        panelAnchor = null;
    }

    function togglePanel(name, anchorItem, onScreen) {
        const screen = anchorItem && anchorItem.screen ? anchorItem.screen : (onScreen || focusedScreen());
        // A second click on the same widget (or IPC toggle) closes; another
        // widget's click moves the panel there.
        if (panel === name && panelScreen === screen && (!anchorItem || anchorItem === panelAnchor))
            closePanel();
        else
            openPanel(name, anchorItem, screen);
    }

    // The screen with Hyprland's focused monitor, or the first screen.
    function focusedScreen() {
        const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++)
            if (screens[i].name === name)
                return screens[i];
        return screens.length > 0 ? screens[0] : null;
    }

    function openSettingsTab(tab, screen) {
        settingsTab = tab;
        openSettings(screen);
    }

    function openSettings(screen) {
        settingsScreen = screen || focusedScreen();
        settingsOpen = true;
        closePanel();
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

    // Full-screen overlays: only one at a time.
    function closeOverlays() {
        sessionOpen = false;
        launcherOpen = false;
        wallpaperOpen = false;
        closePanel();
    }

    function openLauncher(screen, query) {
        launcherQuery = query || "";
        closeOverlays();
        launcherScreen = screen || focusedScreen();
        launcherOpen = true;
    }

    function toggleLauncher(screen) {
        if (launcherOpen)
            launcherOpen = false;
        else
            openLauncher(screen);
    }

    function openWallpaper(screen) {
        closeOverlays();
        wallpaperScreen = screen || focusedScreen();
        wallpaperOpen = true;
    }

    function toggleWallpaper(screen) {
        if (wallpaperOpen)
            wallpaperOpen = false;
        else
            openWallpaper(screen);
    }

    function openSession(screen) {
        closeOverlays();
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
