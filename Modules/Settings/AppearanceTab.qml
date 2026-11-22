import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import qs.Commons
import qs.Components

ColumnLayout {
    id: root

    spacing: Math.round(Style.fontSize * 1.6)

    FolderListModel {
        id: builtinThemes
        folder: "file://" + Theme.builtinDir
        nameFilters: ["*.json"]
        showDirs: false
    }

    FolderListModel {
        id: userThemes
        folder: "file://" + Settings.themesDir
        nameFilters: ["*.json"]
        showDirs: false
    }

    // Built-in themes plus custom ones; a custom theme with a built-in name
    // replaces it, matching how Theme loads them.
    readonly property var themes: {
        const byId = {};
        for (let i = 0; i < builtinThemes.count; i++) {
            const id = builtinThemes.get(i, "fileBaseName");
            byId[id] = { id: id, path: builtinThemes.get(i, "filePath"), custom: false };
        }
        for (let i = 0; i < userThemes.count; i++) {
            const id = userThemes.get(i, "fileBaseName");
            byId[id] = { id: id, path: userThemes.get(i, "filePath"), custom: true };
        }
        return Object.values(byId).sort((a, b) => a.id.localeCompare(b.id));
    }

    readonly property var fontOptions: [{ value: "", label: "System default" }].concat(
        Qt.fontFamilies().map(f => ({ value: f, label: f })))

    SettingsSection {
        title: "Theme"
        description: `Colours used by Vesper. Add your own themes as JSON files in ${Settings.themesDir.replace(Quickshell.env("HOME"), "~")}. A custom theme with the same name as a preset replaces it.`

        Flow {
            Layout.fillWidth: true
            spacing: Math.round(Style.fontSize * 0.7)

            Repeater {
                model: root.themes

                ThemeCard {
                    required property var modelData
                    themeId: modelData.id
                    path: modelData.path
                    isCustom: modelData.custom
                    selected: Theme.themeName === modelData.id
                    onPicked: Settings.set("appearance.theme", modelData.id)
                }
            }
        }

        RowLayout {
            Layout.topMargin: Math.round(Style.fontSize * 0.3)
            VButton {
                iconName: "folder-open"
                text: "Open themes folder"
                onClicked: Quickshell.execDetached(["sh", "-c", 'mkdir -p "$1" && xdg-open "$1"', "sh", Settings.themesDir])
            }
        }
    }

    SettingsSection {
        title: "Fonts"

        SettingsRow {
            label: "Font"
            VComboBox {
                implicitWidth: Style.fontSize * 16
                options: root.fontOptions
                value: Settings.appearance.fontFamily || ""
                onChangedByUser: v => Settings.set("appearance.fontFamily", v)
            }
        }

        SettingsRow {
            label: "Monospace font"
            description: "For places that need fixed-width text."
            VComboBox {
                implicitWidth: Style.fontSize * 16
                options: root.fontOptions
                value: Settings.appearance.monoFontFamily || ""
                onChangedByUser: v => Settings.set("appearance.monoFontFamily", v)
            }
        }

        SettingsRow {
            label: "Font weight"
            description: "For all of Vesper's text. Headings stay bold."
            VComboBox {
                options: [
                    { value: "light", label: "Light" },
                    { value: "normal", label: "Regular" },
                    { value: "medium", label: "Medium" },
                    { value: "demibold", label: "Semibold" }
                ]
                value: Settings.appearance.fontWeight || "medium"
                onChangedByUser: v => Settings.set("appearance.fontWeight", v)
            }
        }

        SettingsRow {
            label: "Interface scale"
            description: "Size of this window, the session menu and other panels. The bar has its own size and scale in Bar settings. Applies when you let go."
            VSlider {
                from: 0.75
                to: 1.5
                stepSize: 0.05
                applyOnRelease: true
                value: Settings.appearance.uiScale
                formatValue: v => Math.round(v * 100) + "%"
                onChangedByUser: v => Settings.set("appearance.uiScale", Math.round(v * 100) / 100)
            }
        }
    }
}
