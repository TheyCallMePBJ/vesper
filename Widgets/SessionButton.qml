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
        icon: root.options.icon || "power"
        iconColor: Panels.sessionOpen ? Theme.accent : Theme.text
        vertical: root.vertical
        barThickness: root.barThickness
        fontSize: root.fontSize
        onClicked: Panels.toggleSession(root.screen)
    }
}
