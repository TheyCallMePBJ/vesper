import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts
import qs.Commons

// Slider with a value label. Bind `value`; handle `changedByUser(real)`.
// With `applyOnRelease`, dragging only moves the slider and changedByUser
// fires once when it's let go (for settings that are costly to apply live).
RowLayout {
    id: root

    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0.01
    // Turns the value into the label text, e.g. v => Math.round(v * 100) + "%"
    property var formatValue: v => String(Math.round(v * 100) / 100)
    property bool applyOnRelease: false

    signal changedByUser(real value)

    spacing: Style.fontSize

    T.Slider {
        id: slider
        Layout.fillWidth: true
        Layout.preferredWidth: Style.fontSize * 14
        from: root.from
        to: root.to
        stepSize: root.stepSize
        snapMode: T.Slider.SnapAlways
        value: root.value
        hoverEnabled: true

        // Keyboard changes (not pressed) always apply immediately.
        onMoved: if (!root.applyOnRelease || !pressed) root.changedByUser(value)
        onPressedChanged: {
            if (pressed)
                return;
            if (root.applyOnRelease && value !== root.value)
                root.changedByUser(value);
            value = Qt.binding(() => root.value);
        }

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: 4
            radius: 2
            color: Theme.surfaceAlt

            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                radius: 2
                color: Theme.accent
            }
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: Math.round(Style.fontSize * 1.2)
            implicitHeight: implicitWidth
            radius: width / 2
            color: slider.pressed ? Qt.lighter(Theme.accent, 1.15) : Theme.accent
            border.width: 2
            border.color: Theme.background
        }

        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }

    VText {
        text: root.formatValue(slider.value)
        color: Theme.textMuted
        horizontalAlignment: Text.AlignRight
        Layout.preferredWidth: Style.fontSize * 3.5
    }
}
