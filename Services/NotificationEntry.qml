import QtQuick
import Quickshell.Services.Notifications

// One notification as Vesper shows it. Keeps a copy of the notification's
// content, so it stays readable in the history after the app closes it (or
// after a restart, when it's loaded from disk with no `notification`).
QtObject {
    id: entry

    // The live notification, or null once it's closed or for loaded history.
    property Notification notification: null

    property real key: 0
    property string appName: ""
    property string appIcon: ""
    property string desktopEntry: ""
    property string summary: ""
    property string body: ""
    property string image: ""
    property int urgency: NotificationUrgency.Normal
    property real time: Date.now()
    // [{ identifier, text }]; only usable while `notification` is set.
    property var actions: []

    readonly property bool live: notification !== null
    readonly property bool critical: urgency === NotificationUrgency.Critical

    // The app changed the notification's content (it sent a replacement).
    signal updated()
    signal closed(int reason)

    function sync() {
        const n = notification;
        if (!n)
            return;
        appName = n.appName || "";
        appIcon = n.appIcon || "";
        desktopEntry = n.desktopEntry || "";
        summary = n.summary || "";
        body = n.body || "";
        image = n.image || "";
        urgency = n.urgency;
        actions = n.actions.map(a => ({ identifier: a.identifier, text: a.text }));
    }

    // Runs one of the app's actions ("default" for a click on the body).
    function invoke(identifier) {
        if (!notification)
            return false;
        const action = notification.actions.find(a => a.identifier === identifier);
        if (!action)
            return false;
        action.invoke();
        return true;
    }

    function dismiss() {
        if (notification)
            notification.dismiss();
    }

    // For notifications.json. Images only survive if they're files.
    function toJson() {
        return {
            key, appName, appIcon, desktopEntry, summary, body, urgency, time,
            image: /^(file:\/\/)?\//.test(image) ? image : ""
        };
    }

    property Connections watcher: Connections {
        target: entry.notification

        function onSummaryChanged() { entry.changed(); }
        function onBodyChanged() { entry.changed(); }
        function onImageChanged() { entry.changed(); }
        function onActionsChanged() { entry.changed(); }
        function onClosed(reason) {
            entry.notification = null;
            entry.closed(reason);
        }
    }

    // Several properties change together on a replacement; update once.
    function changed() {
        Qt.callLater(entry.applyUpdate);
    }
    function applyUpdate() {
        if (!notification)
            return;
        sync();
        time = Date.now();
        updated();
    }
}
