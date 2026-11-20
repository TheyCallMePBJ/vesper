import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Components

// One widget option from WidgetRegistry, shown with the control matching its
// type. Emits changedByUser(value) with the new value.
SettingsRow {
    id: root

    required property var option
    property var value

    signal changedByUser(var value)

    label: option.label || option.key
    description: option.hint || ""

    // Text fields show a newline as \n so multi-line formats stay editable.
    function escapeText(v) {
        return String(v === undefined || v === null ? "" : v).replace(/\n/g, "\\n");
    }
    function unescapeText(t) {
        return t.replace(/\\n/g, "\n");
    }

    Loader {
        sourceComponent: ({
            bool: toggleEditor,
            enum: comboEditor,
            int: spinEditor,
            real: sliderEditor,
            color: colorEditor
        })[root.option.type] || textEditor
    }

    Component {
        id: toggleEditor
        VToggle {
            value: !!root.value
            onChangedByUser: v => root.changedByUser(v)
        }
    }

    Component {
        id: comboEditor
        VComboBox {
            options: root.option.values || []
            value: root.value
            onChangedByUser: v => root.changedByUser(v)
        }
    }

    Component {
        id: spinEditor
        VSpinBox {
            from: root.option.min !== undefined ? root.option.min : 0
            to: root.option.max !== undefined ? root.option.max : 1000
            stepSize: root.option.step || 1
            value: root.value || 0
            onChangedByUser: v => root.changedByUser(v)
        }
    }

    Component {
        id: sliderEditor
        VSlider {
            from: root.option.min !== undefined ? root.option.min : 0
            to: root.option.max !== undefined ? root.option.max : 1
            stepSize: root.option.step || 0.01
            value: root.value || 0
            onChangedByUser: v => root.changedByUser(v)
        }
    }

    Component {
        id: colorEditor
        RowLayout {
            spacing: Math.round(Style.fontSize * 0.5)
            Rectangle {
                implicitWidth: Math.round(Style.fontSize * 1.6)
                implicitHeight: implicitWidth
                radius: Style.radius
                color: Qt.color(root.value || "transparent").valid ? root.value : "transparent"
                border.width: 1
                border.color: Theme.border
            }
            VTextField {
                Layout.preferredWidth: Style.fontSize * 8
                value: root.value || ""
                placeholderText: "#rrggbb"
                onChangedByUser: t => {
                    if (t === "" || Qt.color(t).valid)
                        root.changedByUser(t);
                }
            }
        }
    }

    Component {
        id: textEditor
        VTextField {
            value: root.escapeText(root.value)
            placeholderText: root.escapeText(root.option.default)
            onChangedByUser: t => root.changedByUser(root.unescapeText(t))
        }
    }
}
