import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Components
import qs.Services

ColumnLayout {
    id: root

    spacing: Math.round(Style.fontSize * 1.6)

    readonly property var n: Settings.notifications

    SettingsSection {
        title: "Notifications"

        SettingsRow {
            label: "Receive notifications"
            description: NotificationService.enabled !== (root.n.enabled !== false)
                ? "Restart Vesper for this to take effect."
                : "Turn off to use another notification daemon (mako, dunst, swaync...). Needs a restart."
            VToggle {
                value: root.n.enabled !== false
                onChangedByUser: v => Settings.set("notifications.enabled", v)
            }
        }

        SettingsRow {
            label: "Do not disturb"
            description: "No popups, except critical ones. Notifications still go to the history."
            VToggle {
                value: root.n.doNotDisturb === true
                onChangedByUser: v => Settings.set("notifications.doNotDisturb", v)
            }
        }

        SettingsRow {
            label: "Position"
            VComboBox {
                options: [
                    { value: "top-left", label: "Top left" },
                    { value: "top", label: "Top" },
                    { value: "top-right", label: "Top right" },
                    { value: "bottom-left", label: "Bottom left" },
                    { value: "bottom", label: "Bottom" },
                    { value: "bottom-right", label: "Bottom right" }
                ]
                value: root.n.position
                onChangedByUser: v => Settings.set("notifications.position", v)
            }
        }

        SettingsRow {
            label: "Monitor"
            description: "Where popups appear."
            VComboBox {
                options: [{ value: "", label: "Focused monitor" }].concat(Quickshell.screens.map(s => ({ value: s.name, label: s.name })))
                value: root.n.monitor || ""
                onChangedByUser: v => Settings.set("notifications.monitor", v)
            }
        }

        SettingsRow {
            label: "Most popups at once"
            VSpinBox {
                from: 1
                to: 10
                value: root.n.maxPopups
                onChangedByUser: v => Settings.set("notifications.maxPopups", v)
            }
        }
    }

    SettingsSection {
        title: "How long popups stay"
        description: "Hovering a popup keeps it open. Popups that time out stay in the history."

        SettingsRow {
            label: "Normal"
            VSpinBox {
                from: 1
                to: 60
                suffix: " s"
                value: root.n.timeout
                onChangedByUser: v => Settings.set("notifications.timeout", v)
            }
        }
        SettingsRow {
            label: "Low priority"
            VSpinBox {
                from: 1
                to: 60
                suffix: " s"
                value: root.n.lowTimeout
                onChangedByUser: v => Settings.set("notifications.lowTimeout", v)
            }
        }
        SettingsRow {
            label: "Critical"
            description: "0 keeps them until you dismiss them."
            VSpinBox {
                from: 0
                to: 600
                suffix: " s"
                value: root.n.criticalTimeout
                onChangedByUser: v => Settings.set("notifications.criticalTimeout", v)
            }
        }
        SettingsRow {
            label: "Use the app's timeout"
            description: "When an app asks for a specific time, use that instead."
            VToggle {
                value: root.n.respectAppTimeout === true
                onChangedByUser: v => Settings.set("notifications.respectAppTimeout", v)
            }
        }
    }

    SettingsSection {
        title: "History"

        SettingsRow {
            label: "Notifications to keep"
            description: "0 turns the history off."
            VSpinBox {
                from: 0
                to: 500
                stepSize: 10
                value: root.n.historyLimit
                onChangedByUser: v => Settings.set("notifications.historyLimit", v)
            }
        }

        SettingsRow {
            label: "Clear history"
            VButton {
                text: "Clear"
                iconName: "trash"
                style: "danger"
                enabled: NotificationService.history.length > 0
                onClicked: NotificationService.clearHistory()
            }
        }
    }

    SettingsSection {
        title: "On-screen display"
        description: "A popup showing the new level when the volume or microphone changes."

        SettingsRow {
            label: "Show"
            VToggle {
                value: Settings.osd.enabled === true
                onChangedByUser: v => Settings.set("osd.enabled", v)
            }
        }

        SettingsRow {
            label: "Position"
            enabled: Settings.osd.enabled === true
            VComboBox {
                options: [
                    { value: "top", label: "Top" },
                    { value: "bottom", label: "Bottom" },
                    { value: "left", label: "Left" },
                    { value: "right", label: "Right" }
                ]
                value: Settings.osd.position
                onChangedByUser: v => Settings.set("osd.position", v)
            }
        }

        SettingsRow {
            label: "Visible for"
            enabled: Settings.osd.enabled === true
            VSpinBox {
                from: 500
                to: 10000
                stepSize: 250
                suffix: " ms"
                value: Settings.osd.timeout
                onChangedByUser: v => Settings.set("osd.timeout", v)
            }
        }
    }
}
