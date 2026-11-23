import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Components

ColumnLayout {
    id: root

    spacing: Math.round(Style.fontSize * 1.6)

    SettingsSection {
        title: "Session menu"
        description: "Commands run by the session menu's buttons. Each runs with sh -c."

        SettingsRow {
            label: "Countdown"
            description: "Seconds before log out, reboot and shut down happen. 0 runs them immediately."
            VSpinBox {
                from: 0
                to: 30
                suffix: " s"
                value: Settings.session.countdown
                onChangedByUser: v => Settings.set("session.countdown", v)
            }
        }

        CommandRow {
            label: "Lock"
            description: "Vesper has no lock screen. Set your locker here (e.g. hyprlock); the Lock button is hidden while this is empty."
            key: "lockCommand"
            placeholder: "e.g. hyprlock"
        }
        CommandRow {
            label: "Suspend"
            key: "suspendCommand"
        }
        CommandRow {
            label: "Log out"
            description: "Empty exits Hyprland."
            key: "logoutCommand"
            placeholder: "Exit Hyprland"
        }
        CommandRow {
            label: "Reboot"
            key: "rebootCommand"
        }
        CommandRow {
            label: "Shut down"
            key: "shutdownCommand"
        }
    }

    SettingsSection {
        title: "Control center"
        description: "Which buttons the control center shows."

        Repeater {
            model: [
                { key: "network", label: "Network", hint: "Wi-Fi on/off, or the network panel when wired." },
                { key: "bluetooth", label: "Bluetooth", hint: "" },
                { key: "doNotDisturb", label: "Do not disturb", hint: "" },
                { key: "powerProfile", label: "Power profile", hint: "Needs power-profiles-daemon." },
                { key: "nightLight", label: "Night light", hint: "Only shown when hyprsunset is installed." },
                { key: "keepAwake", label: "Keep awake", hint: "" }
            ]

            SettingsRow {
                required property var modelData
                label: modelData.label
                description: modelData.hint
                VToggle {
                    value: (Settings.controlCenter.buttons || {})[modelData.key] !== false
                    onChangedByUser: v => Settings.set(`controlCenter.buttons.${modelData.key}`, v)
                }
            }
        }
    }

    SettingsSection {
        title: "Audio"

        SettingsRow {
            label: "Volume step"
            description: "How much one scroll step or IPC call changes the volume."
            VSpinBox {
                from: 1
                to: 25
                suffix: " %"
                value: Settings.audio.volumeStep
                onChangedByUser: v => Settings.set("audio.volumeStep", v)
            }
        }
    }

    SettingsSection {
        title: "Calendar"

        SettingsRow {
            label: "First day of the week"
            VComboBox {
                options: [{ value: -1, label: "From locale" }].concat([0, 1, 2, 3, 4, 5, 6].map(d => ({ value: d, label: Qt.locale().dayName(d) })))
                value: Settings.calendar.firstDayOfWeek
                onChangedByUser: v => Settings.set("calendar.firstDayOfWeek", v)
            }
        }

        SettingsRow {
            label: "Show week numbers"
            VToggle {
                value: Settings.calendar.showWeekNumbers === true
                onChangedByUser: v => Settings.set("calendar.showWeekNumbers", v)
            }
        }
    }

    component CommandRow: SettingsRow {
        id: commandRow
        property string key
        property string placeholder: ""

        VTextField {
            implicitWidth: Style.fontSize * 16
            value: Settings.session[commandRow.key] || ""
            placeholderText: commandRow.placeholder
            onChangedByUser: t => Settings.set(`session.${commandRow.key}`, t)
        }
    }
}
