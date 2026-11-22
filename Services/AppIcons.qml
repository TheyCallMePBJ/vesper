pragma Singleton

import QtQuick
import Quickshell

// Icons for apps by app id, desktop entry name or icon name.
Singleton {
    // Icon URL for an app, or "" if none is found. Bindings that call this
    // re-run once the desktop entry list has loaded.
    function forApp(name) {
        if (!name)
            return "";
        const entry = DesktopEntries.applications.values.length >= 0 ? DesktopEntries.heuristicLookup(name) : null;
        const fromEntry = entry && entry.icon ? Quickshell.iconPath(entry.icon, true) : "";
        return fromEntry || Quickshell.iconPath(name, true);
    }

    // The first of several candidate names that has an icon.
    function firstFound(names) {
        for (const n of names) {
            const icon = forApp(n);
            if (icon !== "")
                return icon;
        }
        return "";
    }
}
