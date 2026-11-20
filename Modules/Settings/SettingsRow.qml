import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Components

// Label (and optional description) on the left, control(s) on the right.
RowLayout {
    id: root

    property string label: ""
    property string description: ""
    default property alias control: slot.data

    Layout.fillWidth: true
    spacing: Style.fontSize

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 2

        VText {
            text: root.label
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
        VText {
            visible: root.description !== ""
            text: root.description
            color: Theme.textMuted
            font.pixelSize: Style.fontSize * 0.88
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }

    RowLayout {
        id: slot
        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        spacing: Math.round(Style.fontSize * 0.5)
    }
}
