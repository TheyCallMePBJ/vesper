import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Commons
import qs.Components
import qs.Services

// The drop-down of a Tray widget in drop-down mode: the apps that aren't
// pinned to the bar. Click an icon as usual; right click shows its menu here.
BarPanel {
    id: root

    readonly property var barTray: {
        const w = Settings.barFor(screen ? screen.name : "").widgets || {};
        return [].concat(w.left || [], w.center || [], w.right || []).find(e => e.type === "Tray") || {};
    }
    readonly property var items: TrayService.items(barTray.hidePassive === true).filter(i => !TrayService.isPinned(i))
    readonly property int columns: Math.max(1, Math.min(6, items.length))
    readonly property real cell: Math.round(Style.fontSize * 2)

    // The item whose menu is showing instead of the grid.
    property var menuItem: null

    padding: Math.round(Style.fontSize * 0.4)
    contentSpacing: 0
    panelWidth: menuItem ? Math.max(Math.round(Style.fontSize * 9), (menuLoader.item ? menuLoader.item.implicitWidth : 0) + padding * 2)
              : root.items.length > 0 ? columns * cell + padding * 2
              : Math.round(Style.fontSize * 13)

    GridLayout {
        visible: !root.menuItem && root.items.length > 0
        Layout.alignment: Qt.AlignHCenter
        columns: root.columns
        rowSpacing: 0
        columnSpacing: 0

        Repeater {
            model: root.items

            MouseArea {
                id: cellArea
                required property SystemTrayItem modelData
                implicitWidth: root.cell
                implicitHeight: root.cell
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton || TrayService.activate(modelData, mouse.button)) {
                        if (modelData.hasMenu)
                            root.menuItem = modelData;
                    } else {
                        Panels.closePanel();
                    }
                }
                onWheel: wheel => {
                    const horizontal = wheel.angleDelta.y === 0;
                    modelData.scroll(horizontal ? wheel.angleDelta.x : wheel.angleDelta.y, horizontal);
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Style.radius
                    color: cellArea.pressed ? Theme.surfaceAlt : Theme.surface
                    visible: cellArea.containsMouse
                }
                IconImage {
                    anchors.centerIn: parent
                    source: cellArea.modelData.icon
                    implicitSize: Math.round(Style.fontSize * 1.5)
                    asynchronous: true
                }
            }
        }
    }

    VText {
        visible: !root.menuItem && root.items.length === 0
        Layout.fillWidth: true
        Layout.margins: Math.round(Style.fontSize * 0.4)
        text: TrayService.items(root.barTray.hidePassive === true).length > 0 ? "Every tray app is pinned to the bar." : "No tray apps are running."
        color: Theme.textMuted
        font.pixelSize: Style.fontSize * 0.9
        wrapMode: Text.Wrap
    }

    Loader {
        id: menuLoader
        active: !!root.menuItem
        visible: active
        Layout.fillWidth: true
        sourceComponent: TrayMenuView {
            item: root.menuItem
            maxHeight: root.height * 0.7
            // Back from the top level returns to the icons.
            onDone: Panels.closePanel()
        }
    }

    // Back to the icons from the top of a menu.
    MouseArea {
        visible: !!root.menuItem
        Layout.fillWidth: true
        implicitHeight: Math.round(Style.fontSize * 1.75)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.menuItem = null

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Math.round(Style.fontSize * 0.45)
            spacing: Math.round(Style.fontSize * 0.5)
            VIcon {
                icon: "arrow-left"
                color: Theme.textMuted
                size: Math.round(Style.fontSize * 1.1)
            }
            VText {
                text: "All tray apps"
                color: parent.parent.containsMouse ? Theme.text : Theme.textMuted
                font.pixelSize: Style.fontSize * 0.9
            }
        }
    }

    // A pinned item leaving the grid, or an app quitting, while its menu shows.
    onItemsChanged: if (menuItem && !items.includes(menuItem) && !TrayService.isPinned(menuItem)) menuItem = null
}
