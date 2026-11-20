pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// Lock / suspend / logout / reboot / shutdown, with commands from settings.
Singleton {
    id: root

    // `confirm` actions wait for the countdown in the session menu.
    readonly property var actions: [
        { id: "lock", label: "Lock", icon: "lock", key: "L", confirm: false, command: Settings.session.lockCommand || "" },
        { id: "suspend", label: "Suspend", icon: "zzz", key: "S", confirm: false, command: Settings.session.suspendCommand || "" },
        { id: "logout", label: "Log out", icon: "logout", key: "E", confirm: true, command: Settings.session.logoutCommand || "" },
        { id: "reboot", label: "Reboot", icon: "refresh", key: "R", confirm: true, command: Settings.session.rebootCommand || "" },
        { id: "shutdown", label: "Shut down", icon: "power", key: "P", confirm: true, command: Settings.session.shutdownCommand || "" }
    ]

    // Lock needs a command (Vesper has no lock screen); logout falls back to
    // exiting Hyprland; the rest are hidden if their command is cleared.
    readonly property var available: actions.filter(a => a.command !== "" || a.id === "logout")

    function run(id) {
        const action = actions.find(a => a.id === id);
        if (!action)
            return;
        Logger.i("Session", `Running ${id}`);
        if (action.command !== "")
            Quickshell.execDetached(["sh", "-c", action.command]);
        else if (id === "logout")
            HyprlandService.exit();
    }
}
