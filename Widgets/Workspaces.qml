import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Components
import qs.Services

BarWidget {
    id: root

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight

    function shouldShow(ws) {
        if (!ws)
            return false;
        if (ws.id < 0 && !root.options.showSpecial)
            return false;
        if (root.options.onlyThisMonitor && root.screen && ws.monitor && ws.monitor.name !== root.screen.name)
            return false;
        return true;
    }

    LineLayout {
        id: grid
        anchors.centerIn: parent
        vertical: root.vertical
        spacing: Math.round(root.fontSize * 1.05)

        Repeater {
            model: Hyprland.workspaces

            VText {
                id: label
                required property HyprlandWorkspace modelData
                readonly property bool isFocused: Hyprland.focusedWorkspace?.id === modelData.id

                Layout.alignment: Qt.AlignCenter
                visible: root.shouldShow(modelData)
                text: root.options.labelMode === "name" ? modelData.name : (modelData.id < 0 ? modelData.name.replace(/^special:/, "") : modelData.id)
                color: isFocused ? Theme.accent : (hover.containsMouse ? Theme.text : Theme.textMuted)
                font.pixelSize: root.fontSize
                font.weight: isFocused ? Font.Bold : Style.fontWeight

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: HyprlandService.activate(label.modelData)
                }
            }
        }
    }
}
