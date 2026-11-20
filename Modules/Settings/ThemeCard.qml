import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Components

// Preview of one theme, drawn in that theme's own colours. Click to use it.
Rectangle {
    id: root

    required property string themeId
    required property string path
    property bool isCustom: false
    property bool selected: false

    signal picked

    property string displayName: themeId
    property var colors: Theme.fallback

    implicitWidth: Math.round(Style.fontSize * 12.5)
    implicitHeight: Math.round(Style.fontSize * 5.2)
    radius: Style.radius * 1.5
    color: colors.background || Theme.fallback.background
    border.width: selected ? 2 : 1
    border.color: selected ? Theme.accent : (mouse.containsMouse ? Theme.textMuted : Theme.border)

    FileView {
        path: root.path
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.displayName = data.name || root.themeId;
                root.colors = Object.assign({}, Theme.fallback, data.colors || {});
            } catch (err) {
                root.displayName = root.themeId + " (invalid)";
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.round(Style.fontSize * 0.8)
        spacing: Math.round(Style.fontSize * 0.5)

        RowLayout {
            Layout.fillWidth: true
            VText {
                text: root.displayName
                color: root.colors.text
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            VIcon {
                visible: root.selected
                icon: "check"
                color: root.colors.accent
                size: Style.fontSize * 1.2
            }
        }

        RowLayout {
            spacing: 4
            Repeater {
                model: ["accent", "text", "success", "warning", "error"]
                Rectangle {
                    required property string modelData
                    implicitWidth: Math.round(Style.fontSize * 1.3)
                    implicitHeight: implicitWidth
                    radius: width / 2
                    color: root.colors[modelData]
                    border.width: 1
                    border.color: root.colors.border
                }
            }
            Item { Layout.fillWidth: true }
            VText {
                visible: root.isCustom
                text: "Custom"
                color: root.colors.textMuted
                font.pixelSize: Style.fontSize * 0.85
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked()
    }
}
