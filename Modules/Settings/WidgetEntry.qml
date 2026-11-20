import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Components
import qs.Services

// One widget in the Widgets tab: name, move / options / remove buttons, and
// its options form when expanded.
ColumnLayout {
    id: root

    required property var entry
    property bool canMoveUp: true
    property bool canMoveDown: true
    property bool expanded: false
    property bool vertical: false

    signal moveUp
    signal moveDown
    signal removeRequested
    signal toggleExpanded
    signal optionChanged(string key, var value)

    readonly property var meta: WidgetRegistry.get(entry.type)
    readonly property var options: meta ? WidgetRegistry.resolveOptions(entry) : ({})
    readonly property bool hasOptions: meta !== null && meta.options.length > 0

    Layout.fillWidth: true
    spacing: 0

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: row.implicitHeight + Math.round(Style.fontSize * 0.9)
        radius: Style.radius
        color: Theme.surface
        border.width: 1
        border.color: root.expanded ? Theme.accent : Theme.border

        RowLayout {
            id: row
            anchors.fill: parent
            anchors.leftMargin: Math.round(Style.fontSize * 0.8)
            anchors.rightMargin: Math.round(Style.fontSize * 0.4)
            spacing: Math.round(Style.fontSize * 0.7)

            VIcon {
                icon: root.meta ? (root.meta.icon || "puzzle") : "alert-triangle"
                color: root.meta ? Theme.accent : Theme.error
                size: Style.fontSize * 1.4
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                VText {
                    text: root.meta ? root.meta.name : `${root.entry.type} (unknown widget)`
                    color: root.meta ? Theme.text : Theme.error
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                VText {
                    visible: text !== ""
                    text: root.meta ? (root.meta.description || "") : "Not a widget Vesper knows. It's skipped on the bar."
                    color: Theme.textMuted
                    font.pixelSize: Style.fontSize * 0.88
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            VIconButton {
                iconName: "chevron-up"
                tooltip: root.vertical ? "Move up" : "Move left"
                enabled: root.canMoveUp
                onClicked: root.moveUp()
            }
            VIconButton {
                iconName: "chevron-down"
                tooltip: root.vertical ? "Move down" : "Move right"
                enabled: root.canMoveDown
                onClicked: root.moveDown()
            }
            VIconButton {
                visible: root.hasOptions
                iconName: "adjustments-horizontal"
                tooltip: root.expanded ? "Hide options" : "Options"
                iconColor: root.expanded ? Theme.accent : Theme.text
                onClicked: root.toggleExpanded()
            }
            VIconButton {
                iconName: "trash"
                tooltip: "Remove"
                iconColor: Theme.error
                onClicked: root.removeRequested()
            }
        }
    }

    ColumnLayout {
        visible: root.expanded && root.hasOptions
        Layout.fillWidth: true
        Layout.leftMargin: Style.fontSize
        Layout.rightMargin: Math.round(Style.fontSize * 0.4)
        Layout.topMargin: Math.round(Style.fontSize * 0.8)
        Layout.bottomMargin: Math.round(Style.fontSize * 0.4)
        spacing: Math.round(Style.fontSize * 0.8)

        Repeater {
            model: root.expanded && root.meta ? root.meta.options : []

            OptionEditor {
                required property var modelData
                option: modelData
                value: root.options[modelData.key]
                onChangedByUser: v => root.optionChanged(modelData.key, v)
            }
        }
    }
}
