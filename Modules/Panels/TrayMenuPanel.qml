import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import qs.Commons
import qs.Components
import qs.Services

// A tray app's right-click menu, under its icon on the bar.
BarPanel {
    id: root

    // As wide as the longest entry needs.
    padding: Math.round(Style.fontSize * 0.4)
    contentSpacing: 0
    panelWidth: Math.max(Math.round(Style.fontSize * 9), view.implicitWidth + padding * 2)

    TrayMenuView {
        id: view
        Layout.fillWidth: true
        item: TrayService.menuItem
        maxHeight: root.height * 0.8
        onDone: Panels.closePanel()
    }

    // The app quit while its menu was open.
    readonly property bool appGone: !SystemTray.items.values.includes(TrayService.menuItem)
    onAppGoneChanged: if (appGone) Panels.closePanel()
}
