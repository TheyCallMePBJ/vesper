import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Components
import qs.Services

ColumnLayout {
    id: root

    spacing: Math.round(Style.fontSize * 1.6)

    SettingsSection {
        title: "Search"
        description: "Open the launcher with the Launcher widget, a bar click action, or a keybind: qs -c vesper ipc call launcher toggle"

        SettingsRow {
            label: "Most used apps first"
            description: "Apps you launch often come before others that match as well."
            VToggle {
                value: Settings.launcher.sortByUsage === true
                onChangedByUser: v => Settings.set("launcher.sortByUsage", v)
            }
        }

        SettingsRow {
            label: "Forget app usage"
            VButton {
                text: "Forget"
                iconName: "trash"
                enabled: Object.keys(LauncherService.usage).length > 0
                onClicked: LauncherService.clearUsage()
            }
        }
    }

    SettingsSection {
        title: "Calculator"
        description: "Type a sum (2^10, sqrt 2, 15% * 80) or a conversion (10 km to mi, 72 f to c, 1 GiB in MB). Enter copies the result."

        SettingsRow {
            label: "Calculator and unit conversion"
            VToggle {
                value: Settings.launcher.calculator === true
                onChangedByUser: v => Settings.set("launcher.calculator", v)
            }
        }

        SettingsRow {
            label: "Currency conversion"
            description: "e.g. 100 usd to eur, $20 in inr. Rates come from frankfurter.dev (European Central Bank), fetched when you first convert and kept for 12 hours."
            enabled: Settings.launcher.calculator === true
            VToggle {
                value: Settings.launcher.currency === true
                onChangedByUser: v => Settings.set("launcher.currency", v)
            }
        }
    }

    SettingsSection {
        title: "Launching"

        SettingsRow {
            label: "Terminal"
            description: "For apps that run in a terminal. The app's command is added to the end."
            VTextField {
                implicitWidth: Style.fontSize * 16
                value: Settings.launcher.terminal || ""
                placeholderText: "e.g. kitty -e"
                onChangedByUser: t => Settings.set("launcher.terminal", t.trim())
            }
        }

        SettingsRow {
            label: "Launch prefix"
            description: "Put in front of every app's command, e.g. uwsm app -- or app2unit --. Usually empty."
            VTextField {
                implicitWidth: Style.fontSize * 16
                value: Settings.launcher.launchPrefix || ""
                placeholderText: "None"
                onChangedByUser: t => Settings.set("launcher.launchPrefix", t.trim())
            }
        }
    }
}
