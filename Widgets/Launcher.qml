import QtQuick
import qs.Commons
import qs.Components
import qs.Services

// Opens the launcher.
BarWidget {
    id: root

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    BarPill {
        id: pill
        anchors.centerIn: parent
        icon: root.options.icon || "search"
        iconColor: Panels.launcherOpen ? Theme.accent : Theme.text
        active: Panels.launcherOpen && Panels.launcherScreen === root.screen
        vertical: root.vertical
        barThickness: root.barThickness
        fontSize: root.fontSize
        onClicked: Panels.toggleLauncher(root.screen)
    }
}
