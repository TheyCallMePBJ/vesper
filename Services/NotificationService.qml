pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.Commons

// Vesper's notification daemon: receives notifications, decides which show as
// popups, and keeps a history (saved to ~/.local/state/vesper/notifications.json).
//
// Popups time out into the history without closing the notification, so its
// actions still work from there. Dismissing (the X, or clearing the history)
// closes it for the app.
Singleton {
    id: root

    // Read once: the D-Bus name can't be released and re-taken cleanly, so
    // switching this needs a restart.
    readonly property bool enabled: enabledAtStart
    property bool enabledAtStart: true
    Component.onCompleted: enabledAtStart = Settings.notifications.enabled !== false

    readonly property bool doNotDisturb: Settings.notifications.doNotDisturb === true

    // Newest first.
    property var popups: []
    property var history: []

    // History entries newer than this were added since the history was last
    // looked at.
    property real lastSeen: 0
    readonly property int unread: history.filter(e => e.time > lastSeen).length

    readonly property string historyFile: Settings.stateDir + "/notifications.json"
    property real nextKey: 1

    function setDoNotDisturb(on) {
        Settings.set("notifications.doNotDisturb", on);
    }

    // Everything showing as a popup moves to the history.
    function hideAllPopups() {
        for (const e of popups.slice())
            hidePopup(e);
    }

    function markSeen() {
        lastSeen = Date.now();
        saveTimer.restart();
    }

    // Seconds a popup stays up; 0 = until dismissed.
    function timeoutFor(entry) {
        const s = Settings.notifications;
        if (entry.critical)
            return Math.max(0, s.criticalTimeout || 0);
        const n = entry.notification;
        if (s.respectAppTimeout && n && n.expireTimeout > 0)
            return n.expireTimeout;
        return Math.max(1, (entry.urgency === NotificationUrgency.Low ? s.lowTimeout : s.timeout) || 5);
    }

    // The popup timed out or was hovered away: it stays in the history.
    function hidePopup(entry) {
        popups = popups.filter(e => e !== entry);
        // Transient notifications aren't kept, so close them now.
        if (entry.notification && entry.notification.transient)
            entry.notification.expire();
        release(entry);
    }

    // Close for the app and remove from both lists.
    function dismiss(entry) {
        entry.dismiss();
        remove(entry);
    }

    function remove(entry) {
        popups = popups.filter(e => e !== entry);
        history = history.filter(e => e !== entry);
        release(entry);
        saveTimer.restart();
    }

    function clearHistory() {
        const old = history;
        history = [];
        for (const e of old) {
            if (!popups.includes(e)) {
                e.dismiss();
                e.destroy();
            }
        }
        saveTimer.restart();
    }

    // Body click: run the default action if the app has one.
    function activate(entry) {
        const done = entry.invoke("default");
        if (done && entry.notification && !entry.notification.resident)
            remove(entry);
        else if (done)
            hidePopup(entry);
        return done;
    }

    function invokeAction(entry, identifier) {
        entry.invoke(identifier);
        if (entry.notification && entry.notification.resident)
            return;
        remove(entry);
    }

    // Destroy an entry once nothing shows it any more.
    function release(entry) {
        if (!popups.includes(entry) && !history.includes(entry)) {
            entry.dismiss();
            entry.destroy();
        }
    }

    function add(notification) {
        notification.tracked = true;
        const entry = entryComponent.createObject(root, { notification, key: nextKey++, time: Date.now() });
        entry.sync();
        entry.closed.connect(reason => root.onEntryClosed(entry, reason));
        entry.updated.connect(() => root.onEntryUpdated(entry));

        const limit = Math.max(0, Settings.notifications.historyLimit || 0);
        if (limit > 0 && !notification.transient) {
            const next = [entry].concat(history);
            const dropped = next.splice(limit);
            history = next;
            for (const e of dropped)
                release(e);
            saveTimer.restart();
        }

        // No popups over the open history, or in do not disturb (unless critical).
        const historyOpen = Panels.panel === "notifications";
        if (historyOpen)
            markSeen();
        if (!historyOpen && (!doNotDisturb || entry.critical)) {
            const max = Math.max(1, Settings.notifications.maxPopups || 4);
            const next = [entry].concat(popups);
            const dropped = next.splice(max);
            popups = next;
            for (const e of dropped)
                release(e);
        } else {
            release(entry);
        }
    }

    function onEntryClosed(entry, reason) {
        // The app took it back (e.g. the message was read): forget it.
        if (reason === NotificationCloseReason.CloseRequested) {
            remove(entry);
        } else {
            popups = popups.filter(e => e !== entry);
            release(entry);
        }
    }

    // A replacement re-shows the popup with a fresh timeout.
    function onEntryUpdated(entry) {
        if (!popups.includes(entry) && Panels.panel !== "notifications" && (!doNotDisturb || entry.critical))
            popups = [entry].concat(popups);
        else
            popupUpdated(entry);
        if (history.includes(entry))
            saveTimer.restart();
    }

    signal popupUpdated(var entry)

    Component {
        id: entryComponent
        NotificationEntry {}
    }

    LazyLoader {
        active: root.enabled

        NotificationServer {
            keepOnReload: false
            persistenceSupported: true
            bodySupported: true
            bodyMarkupSupported: true
            bodyHyperlinksSupported: true
            bodyImagesSupported: false
            actionsSupported: true
            imageSupported: true

            onNotification: notification => root.add(notification)
        }
    }

    // ---- History file -----------------------------------------------------

    property bool historyLoaded: false

    FileView {
        id: historyView
        path: root.historyFile
        printErrors: false

        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.lastSeen = data.lastSeen || 0;
                const limit = Math.max(0, Settings.notifications.historyLimit || 0);
                const loaded = (data.history || []).slice(0, limit).map(h => {
                    root.nextKey = Math.max(root.nextKey, (h.key || 0) + 1);
                    return entryComponent.createObject(root, h);
                });
                // Anything that arrived while loading stays on top.
                root.history = root.history.concat(loaded);
            } catch (err) {
                Logger.w("Notifications", `Could not read ${root.historyFile}: ${err.message}`);
            }
            root.historyLoaded = true;
        }
        onLoadFailed: root.historyLoaded = true
        onSaveFailed: error => Logger.e("Notifications", `Could not save ${root.historyFile}: ${FileViewError.toString(error)}`)
    }

    Timer {
        id: saveTimer
        interval: 1000
        onTriggered: {
            if (!root.historyLoaded)
                return restart();
            historyView.setText(JSON.stringify({ lastSeen: root.lastSeen, history: root.history.map(e => e.toJson()) }) + "\n");
        }
    }

    // Shrink the history when the limit is lowered.
    Connections {
        target: Settings
        function onNotificationsChanged() {
            const limit = Math.max(0, Settings.notifications.historyLimit || 0);
            if (root.history.length > limit) {
                const next = root.history.slice();
                const dropped = next.splice(limit);
                root.history = next;
                for (const e of dropped)
                    root.release(e);
                saveTimer.restart();
            }
        }
    }
}
