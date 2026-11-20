import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Components

// A titled card of settings rows.
ColumnLayout {
    id: root

    property string title: ""
    property string description: ""
    default property alias content: body.data

    Layout.fillWidth: true
    spacing: Math.round(Style.fontSize * 0.5)

    VText {
        visible: root.title !== ""
        text: root.title
        font.pixelSize: Style.fontSize * 1.1
        font.bold: true
        Layout.fillWidth: true
    }

    VText {
        visible: root.description !== ""
        text: root.description
        color: Theme.textMuted
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 2
        implicitHeight: body.implicitHeight + padding * 2
        readonly property real padding: Math.round(Style.fontSize * 1.1)
        radius: Style.radius * 1.5
        color: Qt.alpha(Theme.surface, 0.45)
        border.width: 1
        border.color: Qt.alpha(Theme.border, 0.6)

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: parent.padding
            spacing: Math.round(Style.fontSize * 0.9)
        }
    }
}
