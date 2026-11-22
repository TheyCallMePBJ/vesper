import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Components
import qs.Services

ColumnLayout {
    id: root

    spacing: Math.round(Style.fontSize * 1.6)

    SettingsSection {
        title: "Brightness"
        description: BrightnessService.available.length > 0
            ? "Controlling: " + BrightnessService.available.map(m => `${m.name} (${m.method === "ddc" ? "DDC" : "backlight"})`).join(", ")
            : "No screen's brightness can be controlled. Laptop screens need brightnessctl; external monitors need ddcutil and DDC/CI turned on in the monitor's menu."

        SettingsRow {
            label: "Step"
            description: "How much one scroll step or IPC call changes it."
            VSpinBox {
                from: 1
                to: 25
                suffix: " %"
                value: Settings.brightness.step
                onChangedByUser: v => Settings.set("brightness.step", v)
            }
        }

        SettingsRow {
            label: "External monitors (DDC/CI)"
            description: "Uses ddcutil. Turn off if it causes problems with your monitors."
            VToggle {
                value: Settings.brightness.ddc === true
                onChangedByUser: v => Settings.set("brightness.ddc", v)
            }
        }

        SettingsRow {
            label: "Detect monitors again"
            description: "After plugging a monitor in or turning DDC/CI on."
            VButton {
                text: "Detect"
                iconName: "refresh"
                onClicked: BrightnessService.detect()
            }
        }
    }

    SettingsSection {
        title: "Night light"
        description: NightLightService.installed
            ? "Warmer colours in the evening, through hyprsunset (Vesper runs it while night light is on)."
            : "Needs hyprsunset, which isn't installed (e.g. pacman -S hyprsunset). Don't also start it yourself."

        SettingsRow {
            label: "On"
            enabled: NightLightService.installed
            VToggle {
                value: NightLightService.enabled
                onChangedByUser: v => NightLightService.setEnabled(v)
            }
        }

        SettingsRow {
            label: "Temperature"
            description: "Lower is warmer. 6500 K is neutral."
            enabled: NightLightService.installed
            VSlider {
                from: 2500
                to: 6000
                stepSize: 100
                applyOnRelease: true
                value: NightLightService.temperature
                formatValue: v => Math.round(v) + " K"
                onChangedByUser: v => Settings.set("nightLight.temperature", Math.round(v))
            }
        }

        SettingsRow {
            label: "Only at night"
            description: "When on, night light only applies between these times."
            enabled: NightLightService.installed
            VToggle {
                value: Settings.nightLight.schedule === true
                onChangedByUser: v => Settings.set("nightLight.schedule", v)
            }
        }

        SettingsRow {
            label: "From / until"
            description: "24-hour times, e.g. 18:30 and 06:30."
            enabled: NightLightService.installed && Settings.nightLight.schedule === true
            TimeField { key: "start" }
            VText { text: "–"; color: Theme.textMuted }
            TimeField { key: "end" }
        }
    }

    SettingsSection {
        title: "System monitor"
        description: "For the System monitor widget."

        SettingsRow {
            label: "Update every"
            VSpinBox {
                from: 1
                to: 30
                suffix: " s"
                value: Settings.systemMonitor.interval
                onChangedByUser: v => Settings.set("systemMonitor.interval", v)
            }
        }

        SettingsRow {
            label: "Disk"
            description: "Any path on the disk to show."
            VTextField {
                implicitWidth: Style.fontSize * 12
                value: Settings.systemMonitor.diskPath
                onChangedByUser: t => Settings.set("systemMonitor.diskPath", t.trim() || "/")
            }
        }

        SettingsRow {
            label: "Usage warning / critical"
            description: "CPU, memory, GPU and disk turn yellow, then red."
            VSpinBox {
                from: 10
                to: 100
                stepSize: 5
                suffix: " %"
                value: Settings.systemMonitor.warningPercent
                onChangedByUser: v => Settings.set("systemMonitor.warningPercent", v)
            }
            VSpinBox {
                from: 10
                to: 100
                stepSize: 5
                suffix: " %"
                value: Settings.systemMonitor.criticalPercent
                onChangedByUser: v => Settings.set("systemMonitor.criticalPercent", v)
            }
        }

        SettingsRow {
            label: "Temperature warning / critical"
            VSpinBox {
                from: 40
                to: 110
                stepSize: 5
                suffix: " °C"
                value: Settings.systemMonitor.warningTemp
                onChangedByUser: v => Settings.set("systemMonitor.warningTemp", v)
            }
            VSpinBox {
                from: 40
                to: 110
                stepSize: 5
                suffix: " °C"
                value: Settings.systemMonitor.criticalTemp
                onChangedByUser: v => Settings.set("systemMonitor.criticalTemp", v)
            }
        }
    }

    SettingsSection {
        title: "Privacy indicator"

        SettingsRow {
            label: "Ignored apps"
            description: "Apps that record audio all the time (audio effects, visualisers) and shouldn't light up the indicator. Comma-separated, matched by name."
            VTextField {
                implicitWidth: Style.fontSize * 16
                value: (Settings.privacy.ignoredApps || []).join(", ")
                onChangedByUser: t => Settings.set("privacy.ignoredApps", t.split(",").map(a => a.trim()).filter(a => a !== ""))
            }
        }

        SettingsRow {
            label: "Using the microphone now"
            VText {
                text: PrivacyService.micApps.length > 0 ? PrivacyService.micApps.join(", ") : "Nothing"
                color: Theme.textMuted
            }
        }
    }

    component TimeField: VTextField {
        property string key
        implicitWidth: Style.fontSize * 5
        horizontalAlignment: TextInput.AlignHCenter
        value: Settings.nightLight[key] || ""
        validator: RegularExpressionValidator { regularExpression: /^([01]?\d|2[0-3]):[0-5]\d$/ }
        onChangedByUser: t => {
            const m = t.match(/^(\d{1,2}):(\d{2})$/);
            if (m)
                Settings.set(`nightLight.${key}`, m[1].padStart(2, "0") + ":" + m[2]);
        }
    }
}
