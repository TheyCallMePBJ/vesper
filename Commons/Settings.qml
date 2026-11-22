pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Loads ~/.config/vesper/settings.json, merges it over the defaults below and
// reloads whenever the file changes. Read with e.g. `Settings.bar.position`.
// Change values with `Settings.set("bar.position", "left")`, which also saves.
//
// Only keys the user has set are written back to disk; everything else keeps
// following the defaults.
Singleton {
    id: root

    readonly property int currentVersion: 2

    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/vesper"
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/vesper"
    readonly property string settingsFile: configDir + "/settings.json"
    readonly property string themesDir: configDir + "/themes"

    readonly property var defaults: ({
        version: currentVersion,
        bar: {
            position: "top",          // top | bottom | left | right
            height: 30,               // px: height of a horizontal bar / width of a vertical one
            contentScale: 1.0,        // size of text and icons inside the bar
            backgroundOpacity: 0.65,
            padding: 8,
            widgetSpacing: 8,
            monitors: [],             // empty = every monitor
            actions: {
                scroll: "workspace",  // none | workspace | volume
                reverseScroll: false,
                rightClick: { action: "settings" },
                middleClick: { action: "none", command: "" }
            },
            widgets: {
                left: [{ type: "Workspaces" }],
                center: [{ type: "Clock" }],
                right: [{ type: "Tray" }, { type: "Volume" }, { type: "SettingsButton" }, { type: "SessionButton" }]
            }
        },
        monitorOverrides: {},
        appearance: {
            theme: "nord",
            fontFamily: "",
            monoFontFamily: "",
            uiScale: 1.0              // settings window, session menu and other panels
        },
        audio: {
            volumeStep: 5             // percent per scroll step / IPC call
        },
        session: {
            countdown: 3,             // seconds before logout/reboot/shutdown; 0 = immediately
            lockCommand: "",          // empty hides the Lock button
            suspendCommand: "systemctl suspend",
            logoutCommand: "",        // empty = exit Hyprland
            rebootCommand: "systemctl reboot",
            shutdownCommand: "systemctl poweroff"
        },
        osd: {
            enabled: true,            // popup when volume or mic changes
            position: "bottom",       // top | bottom | left | right (centred on that edge)
            timeout: 1500             // ms
        },
        notifications: {
            enabled: true,            // false: Vesper doesn't act as notification daemon (restart to apply)
            doNotDisturb: false,      // no popups; notifications still go to history
            position: "top-right",    // top-left | top | top-right | bottom-left | bottom | bottom-right
            monitor: "",              // empty = focused monitor
            timeout: 5,               // seconds for normal notifications
            lowTimeout: 3,            // seconds for low urgency
            criticalTimeout: 0,       // seconds for critical; 0 = until dismissed
            respectAppTimeout: true,  // use the timeout the app asks for, if any
            maxPopups: 4,
            historyLimit: 100         // 0 = don't keep history
        },
        calendar: {
            firstDayOfWeek: -1,       // -1 = from locale, 0 = Sunday, 1 = Monday, ... 6 = Saturday
            showWeekNumbers: false
        },
        brightness: {
            step: 5,                  // percent per scroll step / IPC call
            ddc: true                 // external monitors through ddcutil
        },
        nightLight: {
            enabled: false,           // master switch (needs hyprsunset)
            temperature: 4000,        // kelvin
            schedule: false,          // only between `start` and `end` while enabled
            start: "18:30",
            end: "06:30"
        },
        systemMonitor: {
            interval: 2,              // seconds between updates
            diskPath: "/",
            warningPercent: 80,       // CPU / memory / disk usage colours
            criticalPercent: 90,
            warningTemp: 75,          // degrees C
            criticalTemp: 90
        },
        privacy: {
            // Apps that record audio all the time and shouldn't count (matched
            // against the PipeWire app or node name, case-insensitive).
            ignoredApps: ["easyeffects", "pavucontrol", "cava"]
        }
    })

    // What the file on disk contains (after migration). Edited by set().
    property var raw: ({})

    // Effective settings, split by section so a change in one section doesn't
    // re-evaluate bindings on the others.
    property var bar: defaults.bar
    property var monitorOverrides: defaults.monitorOverrides
    property var appearance: defaults.appearance
    property var audio: defaults.audio
    property var session: defaults.session
    property var osd: defaults.osd
    property var notifications: defaults.notifications
    property var calendar: defaults.calendar
    property var brightness: defaults.brightness
    property var nightLight: defaults.nightLight
    property var systemMonitor: defaults.systemMonitor
    property var privacy: defaults.privacy

    // Section properties above, kept in sync by apply().
    readonly property var sections: ["bar", "monitorOverrides", "appearance", "audio", "session", "osd", "notifications", "calendar", "brightness", "nightLight", "systemMonitor", "privacy"]

    property bool loaded: false
    // True while set()/reset() changes are waiting to be written. A file load
    // that finishes in that window must not overwrite them.
    property bool dirty: false

    // ---- Public API -------------------------------------------------------

    // Bar config for one screen, with that screen's monitorOverrides applied.
    function barFor(screenName) {
        const override = monitorOverrides[screenName];
        if (!override || typeof override !== "object")
            return bar;
        return Object.assign({}, bar, override);
    }

    // Set a value by dotted path, e.g. set("bar.actions.scroll", "volume").
    function set(path, value) {
        const next = clone(raw);
        const keys = path.split(".");
        let obj = next;
        for (let k = 0; k < keys.length - 1; k++) {
            if (typeof obj[keys[k]] !== "object" || obj[keys[k]] === null || Array.isArray(obj[keys[k]]))
                obj[keys[k]] = {};
            obj = obj[keys[k]];
        }
        obj[keys[keys.length - 1]] = clone(value);
        raw = next;
        dirty = true;
        apply();
        saveTimer.restart();
    }

    // Remove a user value so the default applies again.
    function reset(path) {
        const next = clone(raw);
        const keys = path.split(".");
        let obj = next;
        for (let k = 0; k < keys.length - 1; k++) {
            obj = obj[keys[k]];
            if (typeof obj !== "object" || obj === null)
                return;
        }
        delete obj[keys[keys.length - 1]];
        raw = next;
        dirty = true;
        apply();
        saveTimer.restart();
    }

    function reload() {
        fileView.reload();
    }

    // ---- Internals --------------------------------------------------------

    function clone(v) {
        return v === undefined ? undefined : JSON.parse(JSON.stringify(v));
    }

    function isPlainObject(v) {
        return typeof v === "object" && v !== null && !Array.isArray(v);
    }

    // Defaults overlaid with user values. Objects merge key by key; arrays and
    // scalars from the user replace the default. Keys that exist only in the
    // user's file are kept (e.g. monitorOverrides entries).
    function merge(def, user) {
        if (!isPlainObject(def) || !isPlainObject(user))
            return user === undefined ? clone(def) : clone(user);
        const out = {};
        for (const key in def)
            out[key] = merge(def[key], user[key]);
        for (const key in user)
            if (!(key in def))
                out[key] = clone(user[key]);
        return out;
    }

    function sameJson(a, b) {
        return JSON.stringify(a) === JSON.stringify(b);
    }

    function apply() {
        const merged = merge(defaults, raw);
        // Only reassign sections that actually changed, so unrelated bindings
        // (and the widgets they create) are left alone.
        for (const key of sections)
            if (!sameJson(root[key], merged[key]))
                root[key] = merged[key];
    }

    // Upgrade older settings files. Add one step per version bump:
    //   if (version < 2) { ...change data...; version = 2; }
    function migrate(data) {
        let version = typeof data.version === "number" ? data.version : 1;
        if (version > currentVersion)
            Logger.w("Settings", `settings.json is version ${version}, newer than this Vesper (${currentVersion}). Unknown keys are ignored.`);
        const changed = version < currentVersion;

        if (version < 2) {
            // bar.density presets and appearance.fontScale became an exact
            // bar.height plus separate bar content and interface scales.
            const thickness = { mini: 22, compact: 26, "default": 30, comfortable: 36 };
            const scale = data.appearance && typeof data.appearance.fontScale === "number" ? data.appearance.fontScale : 1;
            const convert = bar => {
                if (!isPlainObject(bar))
                    return;
                if ("density" in bar || scale !== 1) {
                    bar.height = Math.round((thickness[bar.density] || 30) * scale);
                    delete bar.density;
                }
            };
            convert(data.bar);
            if (isPlainObject(data.monitorOverrides))
                for (const name in data.monitorOverrides)
                    convert(data.monitorOverrides[name]);
            if (scale !== 1) {
                data.bar = data.bar || {};
                data.bar.contentScale = scale;
            }
            if (data.appearance && "fontScale" in data.appearance) {
                if (scale !== 1)
                    data.appearance.uiScale = scale;
                delete data.appearance.fontScale;
            }
            version = 2;
        }

        data.version = Math.max(version, currentVersion);
        return changed;
    }

    function parseFile() {
        if (dirty)
            return;
        const text = fileView.text();
        if (text.trim() === "") {
            raw = {};
            apply();
            return;
        }
        let data;
        try {
            data = JSON.parse(text);
        } catch (err) {
            Logger.w("Settings", `${settingsFile} is not valid JSON (${err.message}). Keeping the previous settings.`);
            return;
        }
        if (!isPlainObject(data)) {
            Logger.w("Settings", `${settingsFile} must contain a JSON object. Keeping the previous settings.`);
            return;
        }
        const migrated = migrate(data);
        raw = data;
        apply();
        if (migrated) {
            Logger.i("Settings", `Migrated settings to version ${currentVersion}`);
            save();
        }
    }

    function save() {
        dirty = false;
        fileView.setText(JSON.stringify(raw, null, 2) + "\n");
    }

    FileView {
        id: fileView
        path: root.settingsFile
        watchChanges: true
        blockLoading: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: {
            root.parseFile();
            root.loaded = true;
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                // No settings file (yet, or it was deleted): run on defaults.
                // It's created on the first change.
                if (!root.dirty) {
                    root.raw = {};
                    root.apply();
                }
            } else {
                Logger.w("Settings", `Could not read ${root.settingsFile}: ${FileViewError.toString(error)}`);
            }
            root.loaded = true;
        }
        onSaveFailed: error => Logger.e("Settings", `Could not save ${root.settingsFile}: ${FileViewError.toString(error)}`)
    }

    // Batches rapid changes (e.g. dragging a slider) into one write.
    Timer {
        id: saveTimer
        interval: 300
        onTriggered: root.save()
    }
}
