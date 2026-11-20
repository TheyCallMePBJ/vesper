pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The active colour palette. Loads `appearance.theme` from the user's themes
// folder first, then the built-in Assets/themes, and falls back to the
// built-in palette below if neither exists. User theme files reload live.
Singleton {
    id: root

    readonly property string defaultThemeName: "nord"
    readonly property string builtinDir: Quickshell.shellDir + "/Assets/themes"

    // Used for any colour a theme file leaves out (Nord).
    readonly property var fallback: ({
        background: "#2e3440",
        surface: "#3b4252",
        surfaceAlt: "#434c5e",
        border: "#4c566a",
        text: "#eceff4",
        textMuted: "#9aa3b5",
        accent: "#88c0d0",
        onAccent: "#2e3440",
        success: "#a3be8c",
        warning: "#ebcb8b",
        error: "#bf616a"
    })

    readonly property string themeName: Settings.appearance.theme || defaultThemeName
    property string loadedName: ""
    property var colors: fallback

    readonly property color background: colors.background
    readonly property color surface: colors.surface
    readonly property color surfaceAlt: colors.surfaceAlt
    readonly property color border: colors.border
    readonly property color text: colors.text
    readonly property color textMuted: colors.textMuted
    readonly property color accent: colors.accent
    readonly property color onAccent: colors.onAccent
    readonly property color success: colors.success
    readonly property color warning: colors.warning
    readonly property color error: colors.error

    // Load state per file, reset whenever its path changes. (FileView.loaded
    // stays true from the previous path, so it can't be used for this.)
    property bool userOk: false
    property bool userMissing: false
    property bool builtinOk: false
    property bool builtinMissing: false

    // Pick the user's theme if it exists, else the built-in one, else fallback.
    function refresh() {
        if (userOk) {
            applyThemeText(userFile.text(), userFile.path);
        } else if (userMissing && builtinOk) {
            applyThemeText(builtinFile.text(), builtinFile.path);
        } else if (userMissing && builtinMissing) {
            Logger.w("Theme", `Theme "${themeName}" not found. Using the default colours.`);
            colors = fallback;
            loadedName = "";
        }
        // Otherwise a file is still loading; refresh() runs again when it's done.
    }

    function applyThemeText(text, path) {
        let data;
        try {
            data = JSON.parse(text);
        } catch (err) {
            Logger.w("Theme", `${path} is not valid JSON (${err.message}). Keeping the previous colours.`);
            return;
        }
        const src = (data && typeof data.colors === "object") ? data.colors : {};
        const out = {};
        const missing = [];
        for (const key in fallback) {
            if (typeof src[key] === "string" && Qt.color(src[key]).valid) {
                out[key] = src[key];
            } else {
                out[key] = fallback[key];
                missing.push(key);
            }
        }
        if (missing.length > 0)
            Logger.w("Theme", `${path} is missing or has invalid colours: ${missing.join(", ")}. Using defaults for those.`);
        colors = out;
        loadedName = themeName;
        Logger.i("Theme", `Loaded theme "${data.name || themeName}" from ${path}`);
    }

    // ~/.config/vesper/themes/<name>.json (reloads live when edited)
    FileView {
        id: userFile
        path: Settings.themesDir + "/" + root.themeName + ".json"
        watchChanges: true
        blockLoading: true
        printErrors: false

        onPathChanged: {
            root.userOk = false;
            root.userMissing = false;
        }
        onFileChanged: reload()
        onLoaded: {
            root.userOk = true;
            root.userMissing = false;
            root.refresh();
        }
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                Logger.w("Theme", `Could not read ${path}: ${FileViewError.toString(error)}`);
            root.userOk = false;
            root.userMissing = true;
            root.refresh();
        }
    }

    // Assets/themes/<name>.json
    FileView {
        id: builtinFile
        path: root.builtinDir + "/" + root.themeName + ".json"
        blockLoading: true
        printErrors: false

        onPathChanged: {
            root.builtinOk = false;
            root.builtinMissing = false;
        }
        onLoaded: {
            root.builtinOk = true;
            root.builtinMissing = false;
            root.refresh();
        }
        onLoadFailed: {
            root.builtinOk = false;
            root.builtinMissing = true;
            root.refresh();
        }
    }
}
