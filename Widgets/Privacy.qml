import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as T
import qs.Commons
import qs.Components
import qs.Services

// Shows while an app uses the microphone, camera or screen sharing. Hover
// for which apps.
BarWidget {
    id: root

    readonly property var items: [
        { on: PrivacyService.micInUse && options.showMic, icon: "microphone", label: "Microphone", apps: PrivacyService.micApps },
        { on: PrivacyService.cameraInUse && options.showCamera, icon: "video", label: "Camera", apps: PrivacyService.cameraApps },
        { on: PrivacyService.screenShared && options.showScreen, icon: "screen-share", label: "Screen", apps: PrivacyService.screenApps }
    ].filter(i => i.on)

    shown: items.length > 0
    implicitWidth: shown ? mouse.implicitWidth : 0
    implicitHeight: shown ? mouse.implicitHeight : 0

    MouseArea {
        id: mouse
        anchors.centerIn: parent
        implicitWidth: row.implicitWidth + (root.vertical ? 0 : pad * 2)
        implicitHeight: root.vertical ? row.implicitHeight + pad * 2 : Math.round(root.barThickness * 0.8)
        readonly property real pad: Math.round(root.fontSize * 0.35)
        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        Rectangle {
            anchors.fill: parent
            radius: Style.radius
            color: Qt.alpha(Theme.warning, 0.18)
        }

        LineLayout {
            id: row
            anchors.centerIn: parent
            vertical: root.vertical
            spacing: Math.round(root.fontSize * 0.3)

            Repeater {
                model: root.items
                VIcon {
                    required property var modelData
                    Layout.alignment: Qt.AlignCenter
                    icon: modelData.icon
                    color: Theme.warning
                    size: Math.round(root.fontSize * 1.15)
                }
            }
        }

        T.ToolTip {
            visible: mouse.containsMouse
            delay: 300
            padding: Math.round(Style.fontSize * 0.45)
            contentItem: VText {
                text: root.items.map(i => `${i.label}: ${i.apps.join(", ")}`).join("\n")
                font.pixelSize: Style.fontSize * 0.9
            }
            background: Rectangle {
                radius: Style.radius
                color: Theme.surface
                border.width: 1
                border.color: Theme.border
            }
        }
    }
}
