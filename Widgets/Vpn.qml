import QtQuick
import qs.Commons
import qs.Components
import qs.Services

// VPN status. Click for the network panel.
BarWidget {
    id: root

    readonly property var activeNames: NetworkService.activeVpns.map(v => v.name)

    panelName: "network"
    shown: NetworkService.vpnActive || (!root.options.hideWhenOff && NetworkService.vpns.length > 0)
    implicitWidth: shown ? pill.implicitWidth : 0
    implicitHeight: shown ? pill.implicitHeight : 0

    BarPill {
        id: pill
        anchors.centerIn: parent
        vertical: root.vertical
        barThickness: root.barThickness
        fontSize: root.fontSize
        icon: NetworkService.vpnActive ? "shield-check" : "shield"
        iconColor: NetworkService.vpnActive ? Theme.accent : Theme.textMuted
        text: root.options.showName && root.activeNames.length > 0 ? root.activeNames.join(", ") : ""
        textOnVertical: false
        maxTextWidth: root.fontSize * 10
        active: root.panelOpen
        onClicked: root.togglePanel()
    }
}
