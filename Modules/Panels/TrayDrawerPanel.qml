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
// Keys: arrows move, Enter clicks, Space or the Menu key shows the menu.
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
    // Selected icon (the first one when the drop-down opens, so Enter does
    // something visible), and whether the keyboard opened the menu.
    property int current: 0
    property bool menuByKeys: false

    function showMenu(item, byKeys) {
        if (!item || !item.hasMenu)
            return;
        menuByKeys = byKeys;
        menuItem = item;
    }
    function hideMenu() {
        menuItem = null;
        grid.forceActiveFocus();
    }
    function click(item) {
        if (TrayService.activate(item, Qt.LeftButton))
            showMenu(item, true);
        else
            Panels.closePanel();
    }

    padding: Math.round(Style.fontSize * 0.4)
    contentSpacing: 0
    panelWidth: menuItem ? Math.max(Math.round(Style.fontSize * 9), (menuLoader.item ? menuLoader.item.implicitWidth : 0) + padding * 2)
              : root.items.length > 0 ? columns * cell + padding * 2
              : Math.round(Style.fontSize * 13)

    GridLayout {
        id: grid
        visible: !root.menuItem && root.items.length > 0
        Component.onCompleted: forceActiveFocus()

        Keys.onPressed: event => {
            const n = root.items.length;
            if (n === 0)
                return;
            const k = event.key;
            const step = k === Qt.Key_Right || k === Qt.Key_Tab ? 1
                       : k === Qt.Key_Left || k === Qt.Key_Backtab ? -1
                       : k === Qt.Key_Down ? root.columns
                       : k === Qt.Key_Up ? -root.columns : 0;
            if (step !== 0) {
                root.current = Math.max(0, Math.min(n - 1, root.current + step));
            } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
                root.click(root.items[root.current]);
            } else if (k === Qt.Key_Space || k === Qt.Key_Menu) {
                root.showMenu(root.items[root.current], true);
            } else {
                return;
            }
            event.accepted = true;
        }
        Layout.alignment: Qt.AlignHCenter
        columns: root.columns
        rowSpacing: 0
        columnSpacing: 0

        Repeater {
            model: root.items

            MouseArea {
                id: cellArea
                required property SystemTrayItem modelData
                required property int index
                implicitWidth: root.cell
                implicitHeight: root.cell
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onContainsMouseChanged: if (containsMouse) root.current = index
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton || TrayService.activate(modelData, mouse.button))
                        root.showMenu(modelData, false);
                    else
                        Panels.closePanel();
                }
                onWheel: wheel => {
                    const horizontal = wheel.angleDelta.y === 0;
                    modelData.scroll(horizontal ? wheel.angleDelta.x : wheel.angleDelta.y, horizontal);
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Style.radius
                    color: cellArea.pressed ? Theme.surfaceAlt : Theme.surface
                    visible: root.current === cellArea.index
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
            usingKeys: root.menuByKeys
            current: root.menuByKeys ? 0 : -1
            onDone: Panels.closePanel()
            // Left / Backspace at the top returns to the icons.
            onBackAtTop: root.hideMenu()
        }
        onLoaded: item.forceActiveFocus()
    }

    // Back to the icons from the top of a menu.
    MouseArea {
        visible: !!root.menuItem
        Layout.fillWidth: true
        implicitHeight: Math.round(Style.fontSize * 1.75)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.hideMenu()

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
    onItemsChanged: {
        if (menuItem && !items.includes(menuItem) && !TrayService.isPinned(menuItem))
            hideMenu();
        if (current >= items.length)
            current = Math.max(0, items.length - 1);
    }
}
