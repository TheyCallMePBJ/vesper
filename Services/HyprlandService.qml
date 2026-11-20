pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Hyprland actions. Vesper targets Hyprland with a Lua config, where
// `dispatch` takes a Lua expression (hl.dsp.*), so Quickshell's built-in
// helpers like HyprlandWorkspace.activate() (old syntax) don't work.
Singleton {
    id: root

    // Hyprland.activeToplevel is only set by Hyprland's focus event, so it's
    // empty right after startup. Until that event arrives, use the window
    // Hyprland lists as most recently focused.
    property bool sawFocusEvent: false
    readonly property var activeToplevel: Hyprland.activeToplevel
        || (sawFocusEvent ? null : (Hyprland.toplevels.values.find(t => t.lastIpcObject && t.lastIpcObject.focusHistoryID === 0) || null))

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activewindowv2")
                root.sawFocusEvent = true;
        }
    }

    function luaValue(v) {
        return typeof v === "number" ? String(v) : JSON.stringify(String(v));
    }

    function dispatch(expression) {
        Hyprland.dispatch(expression);
    }

    // target: workspace id, or a relative spec like "m+1" / "e-1".
    function focusWorkspace(target) {
        dispatch(`hl.dsp.focus({workspace=${luaValue(target)}})`);
    }

    // Focus the previous (-1) or next (+1) existing workspace on a monitor,
    // stopping at the first/last one instead of wrapping around. Uses the
    // focused monitor if monitorName is empty or unknown.
    function stepWorkspace(monitorName, direction) {
        const monitor = Hyprland.monitors.values.find(m => m.name === monitorName) || Hyprland.focusedMonitor;
        if (!monitor || !monitor.activeWorkspace)
            return;
        const ids = Hyprland.workspaces.values
            .filter(ws => ws.id > 0 && ws.monitor && ws.monitor.name === monitor.name)
            .map(ws => ws.id)
            .sort((a, b) => a - b);
        const index = ids.indexOf(monitor.activeWorkspace.id);
        const target = ids[index + direction];
        if (index === -1 || target === undefined)
            return;
        focusWorkspace(target);
    }

    // Show/hide a special workspace. Accepts "special:name" or "name".
    function toggleSpecial(name) {
        const bare = String(name).replace(/^special:/, "");
        dispatch(`hl.dsp.workspace.toggle_special(${luaValue(bare)})`);
    }

    // End the Hyprland session (log out).
    function exit() {
        dispatch("hl.dsp.exit()");
    }

    // Click handler for a workspace from Hyprland.workspaces.
    function activate(workspace) {
        if (!workspace)
            return;
        if (workspace.id < 0)
            toggleSpecial(workspace.name);
        else
            focusWorkspace(workspace.id);
    }
}
