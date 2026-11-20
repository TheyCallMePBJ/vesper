import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Commons
import qs.Components

// System tray. Left click: activate (or open the menu for menu-only items).
// Right click: menu. Middle click: secondary action. Scroll: passed to the app.
BarWidget {
    id: root

    readonly property var items: SystemTray.items.values.filter(i => !(root.options.hidePassive && i.status === Status.Passive))

    shown: items.length > 0
    implicitWidth: shown ? grid.implicitWidth : 0
    implicitHeight: shown ? grid.implicitHeight : 0

    LineLayout {
        id: grid
        anchors.centerIn: parent
        vertical: root.vertical
        spacing: 2

        Repeater {
            model: root.items

            MouseArea {
                id: trayItem
                required property SystemTrayItem modelData
                readonly property real size: Math.round(root.barThickness * 0.8)

                Layout.alignment: Qt.AlignCenter
                implicitWidth: size
                implicitHeight: size
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton || (mouse.button === Qt.LeftButton && modelData.onlyMenu)) {
                        if (modelData.hasMenu)
                            menu.open();
                    } else if (mouse.button === Qt.MiddleButton) {
                        modelData.secondaryActivate();
                    } else {
                        modelData.activate();
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
                    opacity: trayItem.containsMouse || menu.visible ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Style.animationDuration } }
                }

                IconImage {
                    anchors.centerIn: parent
                    source: trayItem.modelData.icon
                    implicitSize: Style.barIconSize(root.fontSize)
                    asynchronous: true
                }

                QsMenuAnchor {
                    id: menu
                    menu: trayItem.modelData.menu
                    anchor.item: trayItem
                    anchor.edges: root.vertical ? Edges.Right : Edges.Bottom
                    anchor.gravity: root.vertical ? Edges.Right : Edges.Bottom
                }
            }
        }
    }
}
