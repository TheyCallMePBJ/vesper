pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.Commons

// Tray items, and which ones are pinned to the bar when the Tray widget is a
// drop-down. Pins are kept by the app's tray id in Settings.tray.pinned.
Singleton {
    id: root

    readonly property var pinned: Settings.tray.pinned || []
    // The item whose menu the "trayMenu" panel shows.
    property var menuItem: null

    function items(hidePassive) {
        return SystemTray.items.values.filter(i => !(hidePassive && i.status === Status.Passive));
    }

    function isPinned(item) {
        return !!item && pinned.includes(item.id);
    }

    function setPinned(item, pin) {
        if (!item || isPinned(item) === pin)
            return;
        Settings.set("tray.pinned", pin ? pinned.concat([item.id]) : pinned.filter(id => id !== item.id));
    }

    // Whether any bar's Tray widget is a drop-down (so pinning means something).
    readonly property bool drawerInUse: {
        const all = [Settings.bar].concat(Object.values(Settings.monitorOverrides || {}));
        return all.some(bar => {
            const w = (bar && bar.widgets) || {};
            return [].concat(w.left || [], w.center || [], w.right || []).some(e => e.type === "Tray" && e.drawer === true);
        });
    }

    // Left / middle click / scroll, like a tray normally does. Returns true when
    // the item only has a menu (the caller should show it instead).
    function activate(item, button) {
        if (button === Qt.MiddleButton) {
            item.secondaryActivate();
            return false;
        }
        if (item.onlyMenu)
            return true;
        item.activate();
        return false;
    }

    function openMenu(item, anchorItem, screen) {
        if (!item || !item.hasMenu)
            return;
        menuItem = item;
        Panels.openPanel("trayMenu", anchorItem, screen);
    }
}
