import QtQuick
import qs.Commons
import qs.Components

// Opens the control center.
BarWidget {
    id: root

    panelName: "controlCenter"
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    BarPill {
        id: pill
        anchors.centerIn: parent
        vertical: root.vertical
        barThickness: root.barThickness
        fontSize: root.fontSize
        icon: root.options.icon || "adjustments-horizontal"
        iconColor: root.panelOpen ? Theme.accent : Theme.text
        active: root.panelOpen
        onClicked: root.togglePanel()
    }
}
