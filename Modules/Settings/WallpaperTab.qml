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
        title: "Wallpaper"
        description: "Vesper draws the wallpaper once you pick one, so you don't need hyprpaper, swaybg or similar. Until then, whatever you use now keeps working."

        SettingsRow {
            label: "Draw the wallpaper"
            description: "Off leaves the wallpaper to another program."
            VToggle {
                value: Settings.wallpaper.enabled !== false
                onChangedByUser: v => Settings.set("wallpaper.enabled", v)
            }
        }

        SettingsRow {
            label: "Folder"
            description: WallpaperService.directory === "" ? "Where the picker looks for images."
                : `${WallpaperService.images.length} images found.`
            VTextField {
                implicitWidth: Style.fontSize * 16
                value: Settings.wallpaper.directory || ""
                placeholderText: "~/Pictures/Wallpapers"
                onChangedByUser: t => Settings.set("wallpaper.directory", t.trim())
            }
        }

        SettingsRow {
            label: "Choose a wallpaper"
            RowLayout {
                spacing: Math.round(Style.fontSize * 0.5)
                VButton {
                    text: "Open picker"
                    iconName: "photo"
                    onClicked: Panels.openWallpaper(null)
                }
                VButton {
                    text: "Random"
                    iconName: "arrows-shuffle"
                    enabled: WallpaperService.images.length > 1
                    onClicked: WallpaperService.random("")
                }
            }
        }

        SettingsRow {
            label: "Fit"
            VComboBox {
                options: [
                    { value: "crop", label: "Fill (crop)" },
                    { value: "fit", label: "Fit" },
                    { value: "stretch", label: "Stretch" },
                    { value: "center", label: "Centre" },
                    { value: "tile", label: "Tile" }
                ]
                value: Settings.wallpaper.fillMode
                onChangedByUser: v => Settings.set("wallpaper.fillMode", v)
            }
        }

        SettingsRow {
            label: "Fade"
            description: "Crossfade when the wallpaper changes. 0 switches instantly."
            VSpinBox {
                from: 0
                to: 5000
                stepSize: 100
                suffix: " ms"
                value: Settings.wallpaper.transition
                onChangedByUser: v => Settings.set("wallpaper.transition", v)
            }
        }

        SettingsRow {
            visible: Quickshell.screens.length > 1
            label: "Same wallpaper on every monitor"
            description: "Off: the picker sets the wallpaper of the monitor it opens on."
            VToggle {
                value: Settings.wallpaper.sameOnAllMonitors !== false
                onChangedByUser: v => Settings.set("wallpaper.sameOnAllMonitors", v)
            }
        }

        SettingsRow {
            visible: Object.keys(WallpaperService.paths).length > 0
            label: "Stop drawing the current wallpaper"
            VButton {
                text: "Clear"
                iconName: "x"
                onClicked: WallpaperService.clear()
            }
        }
    }
}
