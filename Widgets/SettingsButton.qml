import QtQuick
import qs.Commons
import qs.Components
import qs.Services

BarWidget {
    id: root

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    BarPill {
        id: pill
        anchors.centerIn: parent
        icon: root.options.icon || "settings"
        iconColor: Panels.settingsOpen ? Theme.accent : Theme.text
        vertical: root.vertical
        barThickness: root.barThickness
        fontSize: root.fontSize
        onClicked: Panels.toggleSettings(root.screen)
    }
}
