import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Components
import qs.Services

// Past notifications, newest first, with do not disturb and clear all.
BarPanel {
    id: root

    panelWidth: Math.round(Style.fontSize * 28)

    // Opening the panel counts as reading everything in it.
    Component.onCompleted: {
        NotificationService.hideAllPopups();
        NotificationService.markSeen();
    }
    Component.onDestruction: NotificationService.markSeen()

    // Refreshes the "5m ago" labels.
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(Style.fontSize * 0.5)

        VIcon {
            icon: NotificationService.doNotDisturb ? "bell-off" : "bell"
            color: Theme.accent
        }
        VText {
            Layout.fillWidth: true
            text: "Notifications"
            font.bold: true
        }
        VText {
            text: "Do not disturb"
            color: Theme.textMuted
            font.pixelSize: Style.fontSize * 0.9
        }
        VToggle {
            value: NotificationService.doNotDisturb
            onChangedByUser: v => NotificationService.setDoNotDisturb(v)
        }
        VIconButton {
            iconName: "trash"
            tooltip: "Clear all"
            enabled: NotificationService.history.length > 0
            onClicked: NotificationService.clearHistory()
        }
    }

    VText {
        visible: !NotificationService.enabled
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Vesper isn't receiving notifications: turn them on in Settings → Notifications, then restart Vesper."
        color: Theme.warning
    }

    // Empty state.
    ColumnLayout {
        visible: NotificationService.history.length === 0
        Layout.fillWidth: true
        Layout.topMargin: Style.fontSize
        Layout.bottomMargin: Style.fontSize
        spacing: Math.round(Style.fontSize * 0.4)

        VIcon {
            Layout.alignment: Qt.AlignHCenter
            icon: "bell-check"
            color: Theme.textMuted
            size: Style.fontSize * 2.5
        }
        VText {
            Layout.alignment: Qt.AlignHCenter
            text: "No notifications"
            color: Theme.textMuted
        }
    }

    ListView {
        id: list
        visible: count > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, (root.screen ? root.screen.height : 1000) * 0.65)
        clip: true
        spacing: Math.round(Style.fontSize * 0.5)
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel { values: NotificationService.history }

        T.ScrollBar.vertical: T.ScrollBar {
            id: scrollBar
            policy: list.contentHeight > list.height ? T.ScrollBar.AlwaysOn : T.ScrollBar.AlwaysOff
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: scrollBar.pressed ? Theme.textMuted : Theme.border
            }
        }

        delegate: NotificationCard {
            required property NotificationEntry modelData
            entry: modelData
            now: clock.date.getTime()
            width: list.width - (scrollBar.visible ? 8 : 0)
        }
    }
}
