pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// Lock / suspend / logout / reboot / shutdown, with commands from settings.
Singleton {
    id: root

    readonly property var defaultKeys: ({ lock: "L", suspend: "S", logout: "E", reboot: "R", shutdown: "P" })

    // The key for each button: from settings, else the default.
    function keyFor(id) {
        const k = (Settings.session.keys || {})[id];
        return typeof k === "string" && k.length === 1 ? k.toUpperCase() : defaultKeys[id];
    }

    // Sets a button's key. A key another button already has is swapped with
    // it, so no two buttons share one.
    function setKey(id, key) {
        const keys = {};
        for (const a of ["lock", "suspend", "logout", "reboot", "shutdown"])
            keys[a] = keyFor(a);
        key = key.toUpperCase();
        const other = Object.keys(keys).find(a => a !== id && keys[a] === key);
        if (other)
            keys[other] = keys[id];
        keys[id] = key;
        Settings.set("session.keys", keys);
    }

    // `confirm` actions wait for the countdown in the session menu.
    readonly property var actions: [
        { id: "lock", label: "Lock", icon: "lock", key: keyFor("lock"), confirm: false, command: Settings.session.lockCommand || "" },
        { id: "suspend", label: "Suspend", icon: "zzz", key: keyFor("suspend"), confirm: false, command: Settings.session.suspendCommand || "" },
        { id: "logout", label: "Log out", icon: "logout", key: keyFor("logout"), confirm: true, command: Settings.session.logoutCommand || "" },
        { id: "reboot", label: "Reboot", icon: "refresh", key: keyFor("reboot"), confirm: true, command: Settings.session.rebootCommand || "" },
        { id: "shutdown", label: "Shut down", icon: "power", key: keyFor("shutdown"), confirm: true, command: Settings.session.shutdownCommand || "" }
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
