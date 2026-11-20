import QtQuick
import QtQuick.Layouts
import qs.Commons

// Whole-number input with - / + buttons. Bind `value`; handle `changedByUser(int)`.
RowLayout {
    id: root

    property int value: 0
    property int from: 0
    property int to: 100
    property int stepSize: 1
    property string suffix: ""

    signal changedByUser(int value)

    function submit(v) {
        const clamped = Math.max(from, Math.min(to, Math.round(v)));
        if (clamped !== value)
            changedByUser(clamped);
    }

    spacing: 4

    VIconButton {
        iconName: "minus"
        enabled: root.value > root.from
        onClicked: root.submit(root.value - root.stepSize)
    }

    VTextField {
        id: field
        Layout.preferredWidth: Style.fontSize * 5
        horizontalAlignment: TextInput.AlignHCenter
        value: String(root.value) + root.suffix
        validator: RegularExpressionValidator { regularExpression: /-?\d*\s*\w*/ }
        onChangedByUser: text => {
            const n = parseInt(text, 10);
            if (!isNaN(n))
                root.submit(n);
        }
    }

    VIconButton {
        iconName: "plus"
        enabled: root.value < root.to
        onClicked: root.submit(root.value + root.stepSize)
    }
}
