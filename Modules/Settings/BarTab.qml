import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Components
import qs.Services

ColumnLayout {
    id: root

    spacing: Math.round(Style.fontSize * 1.6)

    readonly property var monitors: Settings.bar.monitors || []
    readonly property bool vertical: Settings.bar.position === "left" || Settings.bar.position === "right"

    SettingsSection {
        title: "Layout"

        SettingsRow {
            label: "Position"
            VComboBox {
                options: [
                    { value: "top", label: "Top" },
                    { value: "bottom", label: "Bottom" },
                    { value: "left", label: "Left" },
                    { value: "right", label: "Right" }
                ]
                value: Settings.bar.position
                onChangedByUser: v => Settings.set("bar.position", v)
            }
        }

        SettingsRow {
            label: root.vertical ? "Width" : "Height"
            description: "Exact size of the bar in pixels."
            VSpinBox {
                from: 16
                to: 120
                suffix: " px"
                value: Style.barThickness(Settings.bar.height)
                onChangedByUser: v => Settings.set("bar.height", v)
            }
        }

        SettingsRow {
            label: "Content scale"
            description: "Size of the text and icons inside the bar. Applies when you let go."
            VSlider {
                from: 0.5
                to: 2
                stepSize: 0.05
                applyOnRelease: true
                value: Settings.bar.contentScale
                formatValue: v => Math.round(v * 100) + "%"
                onChangedByUser: v => Settings.set("bar.contentScale", Math.round(v * 100) / 100)
            }
        }

        SettingsRow {
            label: "Background opacity"
            VSlider {
                from: 0
                to: 1
                stepSize: 0.05
                value: Settings.bar.backgroundOpacity
                formatValue: v => Math.round(v * 100) + "%"
                onChangedByUser: v => Settings.set("bar.backgroundOpacity", Math.round(v * 100) / 100)
            }
        }

        SettingsRow {
            label: "Edge padding"
            description: "Space between the screen edge and the first and last widgets."
            VSpinBox {
                from: 0
                to: 200
                suffix: " px"
                value: Settings.bar.padding
                onChangedByUser: v => Settings.set("bar.padding", v)
            }
        }

        SettingsRow {
            label: "Widget spacing"
            VSpinBox {
                from: 0
                to: 100
                suffix: " px"
                value: Settings.bar.widgetSpacing
                onChangedByUser: v => Settings.set("bar.widgetSpacing", v)
            }
        }
    }

    SettingsSection {
        title: "Monitors"
        description: "Which monitors show the bar."

        SettingsRow {
            label: "All monitors"
            VToggle {
                value: root.monitors.length === 0
                onChangedByUser: on => Settings.set("bar.monitors", on ? [] : Quickshell.screens.map(s => s.name))
            }
        }

        Repeater {
            model: Quickshell.screens

            SettingsRow {
                id: monitorRow
                required property ShellScreen modelData
                readonly property bool included: root.monitors.includes(modelData.name)

                visible: root.monitors.length > 0
                label: modelData.name
                description: `${modelData.model || "Unknown model"} · ${modelData.width}×${modelData.height}`

                VToggle {
                    value: monitorRow.included
                    // Keep at least one monitor; an empty list means "all".
                    enabled: !(monitorRow.included && root.monitors.length === 1)
                    onChangedByUser: on => {
                        const name = monitorRow.modelData.name;
                        const next = root.monitors.filter(n => n !== name);
                        if (on)
                            next.push(name);
                        Settings.set("bar.monitors", next);
                    }
                }
            }
        }
    }

    SettingsSection {
        title: "Mouse actions"
        description: "What happens when you scroll or click on an empty part of the bar."

        SettingsRow {
            label: "Scroll"
            VComboBox {
                options: BarActions.scrollActions
                value: Settings.bar.actions.scroll
                onChangedByUser: v => Settings.set("bar.actions.scroll", v)
            }
        }

        SettingsRow {
            label: "Reverse scroll direction"
            VToggle {
                value: Settings.bar.actions.reverseScroll
                onChangedByUser: v => Settings.set("bar.actions.reverseScroll", v)
            }
        }

        ClickActionRows {
            label: "Right click"
            key: "rightClick"
        }

        ClickActionRows {
            label: "Middle click"
            key: "middleClick"
        }
    }

    // Action dropdown plus a command field when "Run a command" is chosen.
    component ClickActionRows: ColumnLayout {
        id: clickRows
        property string label
        property string key
        readonly property var current: Settings.bar.actions[key] || ({})

        Layout.fillWidth: true
        spacing: Math.round(Style.fontSize * 0.9)

        SettingsRow {
            label: clickRows.label
            VComboBox {
                options: BarActions.clickActions
                value: clickRows.current.action || "none"
                onChangedByUser: v => Settings.set(`bar.actions.${clickRows.key}.action`, v)
            }
        }

        SettingsRow {
            visible: clickRows.current.action === "command"
            label: "Command"
            description: "Runs with sh -c."
            VTextField {
                value: clickRows.current.command || ""
                placeholderText: "e.g. kitty"
                onChangedByUser: t => Settings.set(`bar.actions.${clickRows.key}.command`, t)
            }
        }
    }
}
