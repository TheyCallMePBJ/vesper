pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// Every bar widget type Vesper knows about. To add a widget, create
// Widgets/<Name>.qml and add an entry here.
//
// Option types (the settings window builds its form from these):
//   bool | text | int (min, max, step) | real (min, max, step)
//   enum (values: [{ value, label }]) | color | command
Singleton {
    id: root

    readonly property var widgets: ({
        "Workspaces": {
            component: "Workspaces.qml",
            name: "Workspaces",
            icon: "layout-grid",
            description: "Hyprland workspaces. Click to switch.",
            allowMultiple: false,
            options: [
                { key: "labelMode", type: "enum", label: "Label", default: "number",
                  values: [{ value: "number", label: "Number" }, { value: "name", label: "Name" }] },
                { key: "onlyThisMonitor", type: "bool", label: "Only show this monitor's workspaces", default: false },
                { key: "showSpecial", type: "bool", label: "Show special (scratchpad) workspaces", default: false }
            ]
        },
        "Clock": {
            component: "Clock.qml",
            name: "Clock",
            icon: "clock",
            description: "Date and time. Click to open the calendar.",
            allowMultiple: true,
            options: [
                { key: "format", type: "text", label: "Format", default: "HH:mm - dd/MM",
                  hint: "Qt date format, e.g. HH:mm:ss ddd d MMM" },
                { key: "formatVertical", type: "text", label: "Format on a vertical bar", default: "HH\nmm" }
            ]
        },
        "ActiveWindow": {
            component: "ActiveWindow.qml",
            name: "Active window",
            icon: "app-window",
            description: "Icon and title of the focused window.",
            allowMultiple: false,
            options: [
                { key: "showIcon", type: "bool", label: "Show app icon", default: true },
                { key: "showTitle", type: "bool", label: "Show title", default: true, hint: "Never shown on vertical bars." },
                { key: "maxWidth", type: "int", label: "Max title width", default: 300, min: 50, max: 1000, step: 10 }
            ]
        },
        "Tray": {
            component: "Tray.qml",
            name: "System tray",
            icon: "dots",
            description: "Tray icons of running apps. Right click for their menu.",
            allowMultiple: false,
            options: [
                { key: "hidePassive", type: "bool", label: "Hide passive items", default: false,
                  hint: "Some apps mark their icon as passive when idle." }
            ]
        },
        "Volume": {
            component: "Volume.qml",
            name: "Volume",
            icon: "volume",
            description: "Click for the audio panel, middle click to mute, scroll to change volume.",
            allowMultiple: false,
            options: [
                { key: "showPercent", type: "bool", label: "Show percentage", default: true },
                { key: "clickAction", type: "enum", label: "Left click", default: "panel",
                  values: [{ value: "panel", label: "Open audio panel" }, { value: "mute", label: "Mute" }] },
                { key: "rightClickCommand", type: "command", label: "Right click command", default: "pavucontrol" }
            ]
        },
        "Microphone": {
            component: "Microphone.qml",
            name: "Microphone",
            icon: "microphone",
            description: "Click for the audio panel, middle click to mute, scroll to change input volume.",
            allowMultiple: false,
            options: [
                { key: "showPercent", type: "bool", label: "Show percentage", default: false },
                { key: "clickAction", type: "enum", label: "Left click", default: "panel",
                  values: [{ value: "panel", label: "Open audio panel" }, { value: "mute", label: "Mute" }] },
                { key: "rightClickCommand", type: "command", label: "Right click command", default: "pavucontrol" }
            ]
        },
        "Media": {
            component: "Media.qml",
            name: "Media",
            icon: "music",
            description: "Now playing. Click: play/pause, right click: next, middle click: previous.",
            allowMultiple: false,
            options: [
                { key: "showArtist", type: "bool", label: "Show artist", default: true },
                { key: "hideWhenPaused", type: "bool", label: "Hide when nothing is playing", default: false },
                { key: "maxWidth", type: "int", label: "Max width", default: 250, min: 50, max: 1000, step: 10 }
            ]
        },
        "Bluetooth": {
            component: "BluetoothWidget.qml",
            name: "Bluetooth",
            icon: "bluetooth",
            description: "Bluetooth status. Click to turn it on or off.",
            allowMultiple: false,
            options: [
                { key: "showDeviceName", type: "bool", label: "Show connected device", default: false }
            ]
        },
        "Notifications": {
            component: "Notifications.qml",
            name: "Notifications",
            icon: "bell",
            description: "Unread notifications. Click for the history, right click for do not disturb.",
            allowMultiple: false,
            options: [
                { key: "showCount", type: "bool", label: "Show unread count", default: true },
                { key: "hideWhenEmpty", type: "bool", label: "Hide when there are no notifications", default: false }
            ]
        },
        "Battery": {
            component: "Battery.qml",
            name: "Battery",
            icon: "battery-3",
            description: "Laptop battery. Hidden if there's no battery.",
            allowMultiple: false,
            options: [
                { key: "showPercent", type: "bool", label: "Show percentage", default: true },
                { key: "warningPercent", type: "int", label: "Warn below", default: 15, min: 0, max: 100, step: 5 }
            ]
        },
        "PowerProfile": {
            component: "PowerProfileWidget.qml",
            name: "Power profile",
            icon: "gauge",
            description: "Click to switch between power saver, balanced and performance.",
            allowMultiple: false,
            options: [
                { key: "showLabel", type: "bool", label: "Show profile name", default: false }
            ]
        },
        "KeyboardLayout": {
            component: "KeyboardLayout.qml",
            name: "Keyboard layout",
            icon: "keyboard",
            description: "Active layout. Click to switch to the next one.",
            allowMultiple: false,
            options: [
                { key: "display", type: "enum", label: "Show", default: "code",
                  values: [{ value: "code", label: "Code (US)" }, { value: "name", label: "Name (English (US))" }] },
                { key: "showIcon", type: "bool", label: "Show icon", default: true }
            ]
        },
        "LockKeys": {
            component: "LockKeys.qml",
            name: "Lock keys",
            icon: "letter-a",
            description: "Caps Lock / Num Lock indicators.",
            allowMultiple: false,
            options: [
                { key: "showCaps", type: "bool", label: "Caps Lock", default: true },
                { key: "showNum", type: "bool", label: "Num Lock", default: true },
                { key: "showScroll", type: "bool", label: "Scroll Lock", default: false },
                { key: "hideWhenOff", type: "bool", label: "Only show keys that are on", default: false }
            ]
        },
        "ControlCenter": {
            component: "ControlCenter.qml",
            name: "Control center",
            icon: "adjustments-horizontal",
            description: "Opens the control center: volume, toggles, media and session.",
            allowMultiple: false,
            options: [
                { key: "icon", type: "text", label: "Icon", default: "adjustments-horizontal", hint: "Tabler icon name (tabler.io/icons)." }
            ]
        },
        "CustomButton": {
            component: "CustomButton.qml",
            name: "Custom button",
            icon: "terminal-2",
            description: "Your own icon and label that runs commands.",
            allowMultiple: true,
            options: [
                { key: "icon", type: "text", label: "Icon", default: "terminal-2", hint: "Tabler icon name (tabler.io/icons). Empty for none." },
                { key: "label", type: "text", label: "Label", default: "" },
                { key: "labelCommand", type: "command", label: "Label from command", default: "",
                  hint: "First line of its output replaces the label." },
                { key: "labelInterval", type: "int", label: "Label refresh (seconds)", default: 10, min: 1, max: 3600, step: 1 },
                { key: "leftClick", type: "command", label: "Left click", default: "" },
                { key: "rightClick", type: "command", label: "Right click", default: "" },
                { key: "middleClick", type: "command", label: "Middle click", default: "" }
            ]
        },
        "Text": {
            component: "TextWidget.qml",
            name: "Text",
            icon: "typography",
            description: "Fixed text or the output of a command.",
            allowMultiple: true,
            options: [
                { key: "text", type: "text", label: "Text", default: "" },
                { key: "command", type: "command", label: "Command", default: "",
                  hint: "If set, its first output line is shown instead of the text." },
                { key: "interval", type: "int", label: "Refresh (seconds)", default: 10, min: 1, max: 3600, step: 1 },
                { key: "color", type: "color", label: "Colour", default: "", hint: "Empty uses the theme's text colour." }
            ]
        },
        "SessionButton": {
            component: "SessionButton.qml",
            name: "Session button",
            icon: "power",
            description: "Opens the session menu (lock, suspend, log out, reboot, shut down).",
            allowMultiple: false,
            options: [
                { key: "icon", type: "text", label: "Icon", default: "power", hint: "Tabler icon name (tabler.io/icons)." }
            ]
        },
        "SettingsButton": {
            component: "SettingsButton.qml",
            name: "Settings button",
            description: "Opens Vesper's settings.",
            icon: "settings",
            allowMultiple: false,
            options: [
                { key: "icon", type: "text", label: "Icon", default: "settings",
                  hint: "Any Tabler icon name, see tabler.io/icons" }
            ]
        },
        "Spacer": {
            component: "Spacer.qml",
            name: "Spacer",
            icon: "separator-vertical",
            description: "Empty space.",
            allowMultiple: true,
            options: [
                { key: "size", type: "int", label: "Size", default: 16, min: 1, max: 500, step: 1 }
            ]
        }
    })

    // Types in display order, for "Add widget" menus.
    readonly property var types: Object.keys(widgets).sort((a, b) => widgets[a].name.localeCompare(widgets[b].name))

    function has(type) {
        return Object.prototype.hasOwnProperty.call(widgets, type);
    }

    function get(type) {
        return has(type) ? widgets[type] : null;
    }

    function url(type) {
        const meta = get(type);
        return meta ? Qt.resolvedUrl("../Widgets/" + meta.component) : "";
    }

    function defaults(type) {
        const meta = get(type);
        const out = {};
        if (meta)
            for (const opt of meta.options)
                out[opt.key] = opt.default;
        return out;
    }

    // Defaults overlaid with the options stored in a bar entry.
    function resolveOptions(entry) {
        return Object.assign(defaults(entry.type), entry);
    }

    // Strip options equal to their default, for saving.
    function compactEntry(entry) {
        const defs = defaults(entry.type);
        const out = { type: entry.type };
        for (const key in entry)
            if (key !== "type" && JSON.stringify(entry[key]) !== JSON.stringify(defs[key]))
                out[key] = entry[key];
        return out;
    }

    // Warn once per unknown type instead of on every rebuild.
    property var warnedTypes: ({})
    function warnUnknown(type) {
        if (warnedTypes[type])
            return;
        warnedTypes[type] = true;
        Logger.w("Widgets", `Unknown widget type "${type}" in settings, skipping it.`);
    }
}
