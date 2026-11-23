import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Commons
import qs.Components
import qs.Services

// System tray. Left click: activate (or open the menu for menu-only items).
// Right click: menu. Middle click: secondary action. Scroll: passed to the app.
// As a drop-down, only pinned apps stay on the bar and an arrow opens the rest.
BarWidget {
    id: root

    readonly property bool drawer: root.options.drawer === true
    readonly property var allItems: TrayService.items(root.options.hidePassive)
    readonly property var barItems: drawer ? allItems.filter(i => TrayService.isPinned(i)) : allItems
    readonly property bool hasHidden: drawer && barItems.length < allItems.length
    readonly property string barPosition: Settings.barFor(screen ? screen.name : "").position

    panelName: "tray"
    shown: allItems.length > 0
    implicitWidth: shown ? grid.implicitWidth : 0
    implicitHeight: shown ? grid.implicitHeight : 0

    LineLayout {
        id: grid
        anchors.centerIn: parent
        vertical: root.vertical
        spacing: 2

        Repeater {
            model: root.barItems

            MouseArea {
                id: trayItem
                required property SystemTrayItem modelData
                readonly property real size: Math.round(root.barThickness * 0.8)
                readonly property bool menuOpen: Panels.panel === "trayMenu" && Panels.panelAnchor === trayItem

                Layout.alignment: Qt.AlignCenter
                implicitWidth: size
                implicitHeight: size
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton || TrayService.activate(modelData, mouse.button)) {
                        if (menuOpen)
                            Panels.closePanel();
                        else
                            TrayService.openMenu(modelData, trayItem, root.screen);
                    }
                }
                onWheel: wheel => {
                    const horizontal = wheel.angleDelta.y === 0;
                    modelData.scroll(horizontal ? wheel.angleDelta.x : wheel.angleDelta.y, horizontal);
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Style.radius
                    color: trayItem.pressed ? Theme.surfaceAlt : Theme.surface
                    opacity: trayItem.containsMouse || trayItem.menuOpen ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Style.animationDuration } }
                }

                IconImage {
                    anchors.centerIn: parent
                    source: trayItem.modelData.icon
                    implicitSize: Style.barIconSize(root.fontSize)
                    asynchronous: true
                }
            }
        }

        // Opens the drop-down with the apps that aren't pinned.
        BarPill {
            visible: root.hasHidden
            Layout.alignment: Qt.AlignCenter
            icon: ({ top: "chevron-down", bottom: "chevron-up", left: "chevron-right", right: "chevron-left" })[root.barPosition] || "chevron-down"
            iconColor: root.panelOpen ? Theme.accent : Theme.textMuted
            active: root.panelOpen
            vertical: root.vertical
            barThickness: root.barThickness
            fontSize: root.fontSize
            onClicked: root.togglePanel()
        }
    }
}
