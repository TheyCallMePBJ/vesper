import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Components
import qs.Services

// Connection status: wired, or Wi-Fi by signal strength, plus a shield while a
// VPN is connected. Click for the network panel.
BarWidget {
    id: root

    readonly property bool wired: NetworkService.wiredDevice !== null
    readonly property bool wifi: !wired && NetworkService.wifiConnected
    readonly property bool online: wired || wifi
    readonly property color color: !online ? Theme.textMuted
                                  : NetworkService.connectivity === "full" || NetworkService.connectivity === "unknown" ? Theme.text : Theme.warning
    readonly property real pad: Math.round(fontSize * 0.35)
    readonly property real iconSize: Style.barIconSize(fontSize)

    // Same size as a BarPill across the bar, so the icon lands on the same
    // pixel row as the icons in other widgets.
    readonly property real cell: Math.round(barThickness * 0.8)

    panelName: "network"
    implicitWidth: vertical ? cell : content.implicitWidth
    implicitHeight: vertical ? content.implicitHeight : cell

    MouseArea {
        id: mouse
        // Hover background like BarPill: outside the content along the bar.
        anchors.centerIn: parent
        width: root.vertical ? Math.round(root.barThickness * 0.8) : parent.width + root.pad * 2
        height: root.vertical ? parent.height + root.pad * 2 : Math.round(root.barThickness * 0.8)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePanel()

        Rectangle {
            anchors.fill: parent
            radius: Style.radius
            color: mouse.pressed ? Theme.surfaceAlt : Theme.surface
            opacity: root.panelOpen || mouse.containsMouse || mouse.pressed ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Style.animationDuration } }
        }
    }

    LineLayout {
        id: content
        anchors.centerIn: parent
        vertical: root.vertical
        spacing: Math.round(root.fontSize * (root.vertical ? 0.15 : 0.3))

        VIcon {
            Layout.alignment: Qt.AlignCenter
            icon: NetworkService.icon
            color: root.color
            size: root.iconSize
        }

        VIcon {
            Layout.alignment: Qt.AlignCenter
            visible: NetworkService.vpnActive
            icon: "shield-check"
            color: root.color
            size: root.iconSize
        }

        VText {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: Math.min(implicitWidth, root.fontSize * 10)
            visible: root.options.showName && root.online && !root.vertical
            text: NetworkService.label
            color: root.color
            font.pixelSize: root.fontSize
            elide: Text.ElideRight
        }
    }
}
