import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Components
import qs.Services

// Wired status, Wi-Fi on/off and networks, and VPN connections.
BarPanel {
    id: root

    panelWidth: Math.round(Style.fontSize * 26)

    // The Wi-Fi network whose row is expanded (password / disconnect / forget).
    property string expanded: ""
    property string password: ""

    Component.onCompleted: {
        NetworkService.scanners++;
        NetworkService.lastError = "";
        NetworkService.refresh();
    }
    Component.onDestruction: NetworkService.scanners--

    // ---- Header ------------------------------------------------------------

    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(Style.fontSize * 0.5)

        VIcon {
            icon: NetworkService.icon
            color: Theme.accent
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            VText {
                text: "Network"
                font.bold: true
            }
            VText {
                Layout.fillWidth: true
                text: {
                    if (!NetworkService.available)
                        return "NetworkManager isn't running";
                    if (!NetworkService.connected)
                        return "Not connected";
                    const parts = [NetworkService.label];
                    if (NetworkService.connectivity === "portal")
                        parts.push("sign-in required");
                    else if (NetworkService.connectivity !== "full" && NetworkService.connectivity !== "unknown")
                        parts.push("no internet");
                    if (NetworkService.vpnActive)
                        parts.push("VPN: " + NetworkService.activeVpns.map(v => v.name).join(", "));
                    return parts.join(" · ");
                }
                color: Theme.textMuted
                font.pixelSize: Style.fontSize * 0.88
                elide: Text.ElideRight
            }
        }
        VIconButton {
            visible: NetworkService.hasWifi && NetworkService.wifiEnabled
            iconName: "refresh"
            tooltip: "Scan"
            onClicked: NetworkService.rescan()
        }
    }

    VText {
        visible: NetworkService.lastError !== ""
        Layout.fillWidth: true
        text: NetworkService.lastError
        color: Theme.error
        wrapMode: Text.Wrap
        font.pixelSize: Style.fontSize * 0.9
    }

    // ---- Wired ---------------------------------------------------------------

    Repeater {
        model: NetworkService.devices.filter(d => d.type === "ethernet")

        Row_ {
            required property var modelData
            icon: modelData.state === "connected" ? "network" : "network-off"
            title: modelData.state === "connected" ? (modelData.connection || "Wired") : "Ethernet"
            detail: modelData.state === "connected" ? `Connected · ${modelData.name}` : modelData.state === "unavailable" ? "Cable unplugged" : modelData.state
            highlighted: modelData.state === "connected"
        }
    }

    // ---- Wi-Fi -------------------------------------------------------------

    RowLayout {
        visible: NetworkService.hasWifi
        Layout.fillWidth: true
        Layout.topMargin: Math.round(Style.fontSize * 0.3)

        VIcon {
            icon: NetworkService.wifiEnabled ? "wifi" : "wifi-off"
            color: Theme.accent
        }
        VText {
            Layout.fillWidth: true
            text: "Wi-Fi"
            font.bold: true
        }
        VToggle {
            value: NetworkService.wifiEnabled
            onChangedByUser: v => NetworkService.setWifiEnabled(v)
        }
    }

    VText {
        visible: NetworkService.hasWifi && NetworkService.wifiEnabled && NetworkService.wifiNetworks.length === 0
        Layout.fillWidth: true
        text: "Looking for networks..."
        color: Theme.textMuted
    }

    Flickable {
        id: wifiList
        visible: NetworkService.hasWifi && NetworkService.wifiEnabled && NetworkService.wifiNetworks.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, Style.fontSize * 22)
        contentHeight: wifiColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        T.ScrollBar.vertical: T.ScrollBar {
            id: wifiScroll
            policy: wifiList.contentHeight > wifiList.height ? T.ScrollBar.AlwaysOn : T.ScrollBar.AlwaysOff
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: Theme.border
            }
        }

        ColumnLayout {
            id: wifiColumn
            width: wifiList.width - (wifiScroll.visible ? 8 : 0)
            spacing: 2

            Repeater {
                model: NetworkService.wifiNetworks

                ColumnLayout {
                    id: net
                    required property var modelData
                    readonly property bool open: root.expanded === modelData.ssid
                    readonly property bool busy: NetworkService.busy === modelData.ssid
                    readonly property bool needsPassword: !modelData.known && modelData.security !== ""

                    Layout.fillWidth: true
                    spacing: 2

                    Row_ {
                        icon: NetworkService.wifiIcon(net.modelData.signal)
                        title: net.modelData.ssid
                        detail: net.busy ? "Connecting..."
                              : net.modelData.inUse ? "Connected"
                              : net.modelData.known ? "Saved" : (net.modelData.security || "Open")
                        trailingIcon: net.modelData.security !== "" ? "lock" : ""
                        highlighted: net.modelData.inUse
                        clickable: true
                        onClicked: {
                            // Connected or new secured networks expand; others connect.
                            if (net.modelData.inUse || net.needsPassword) {
                                root.expanded = net.open ? "" : net.modelData.ssid;
                                root.password = "";
                            } else {
                                root.expanded = "";
                                NetworkService.connectWifi(net.modelData.ssid, "");
                            }
                        }
                    }

                    // Password for a new secured network.
                    RowLayout {
                        visible: net.open && net.needsPassword
                        Layout.fillWidth: true
                        Layout.leftMargin: Math.round(Style.fontSize * 0.6)
                        Layout.bottomMargin: Math.round(Style.fontSize * 0.3)

                        VTextField {
                            id: passwordField
                            Layout.fillWidth: true
                            implicitWidth: 0
                            echoMode: TextInput.Password
                            placeholderText: "Password"
                            value: root.password
                            onChangedByUser: t => root.password = t
                            onAccepted: NetworkService.connectWifi(net.modelData.ssid, text)
                            onVisibleChanged: if (visible) forceActiveFocus()
                        }
                        VButton {
                            text: "Connect"
                            style: "primary"
                            enabled: !net.busy
                            onClicked: NetworkService.connectWifi(net.modelData.ssid, passwordField.text || root.password)
                        }
                    }

                    // Connected network: disconnect / forget.
                    RowLayout {
                        visible: net.open && net.modelData.inUse
                        Layout.leftMargin: Math.round(Style.fontSize * 0.6)
                        Layout.bottomMargin: Math.round(Style.fontSize * 0.3)

                        VButton {
                            text: "Disconnect"
                            onClicked: {
                                root.expanded = "";
                                NetworkService.disconnectWifi();
                            }
                        }
                        VButton {
                            text: "Forget"
                            style: "danger"
                            onClicked: {
                                root.expanded = "";
                                NetworkService.forgetWifi(net.modelData.ssid);
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- VPN ---------------------------------------------------------------

    RowLayout {
        visible: NetworkService.vpns.length > 0 || NetworkService.externalTunnels.length > 0
        Layout.fillWidth: true
        Layout.topMargin: Math.round(Style.fontSize * 0.3)

        VIcon {
            icon: NetworkService.vpnActive ? "shield-check" : "shield"
            color: Theme.accent
        }
        VText {
            Layout.fillWidth: true
            text: "VPN"
            font.bold: true
        }
    }

    Repeater {
        model: NetworkService.vpns

        RowLayout {
            id: vpn
            required property var modelData
            readonly property bool busy: NetworkService.busy === modelData.uuid
            Layout.fillWidth: true

            Row_ {
                Layout.fillWidth: true
                icon: vpn.modelData.active ? "shield-check" : "shield"
                title: vpn.modelData.name
                detail: vpn.busy ? (vpn.modelData.active ? "Disconnecting..." : "Connecting...") : vpn.modelData.active ? "Connected" : "Off"
                highlighted: vpn.modelData.active
            }
            VToggle {
                value: vpn.modelData.active
                enabled: !vpn.busy
                onChangedByUser: v => NetworkService.setVpn(vpn.modelData.uuid, v)
            }
        }
    }

    Repeater {
        model: NetworkService.externalTunnels

        Row_ {
            required property var modelData
            icon: "topology-star-3"
            title: modelData.name
            detail: "Tunnel · managed outside NetworkManager"
        }
    }

    // ---- Pieces ------------------------------------------------------------

    // One list row: icon, title and detail line, optional trailing icon.
    component Row_: MouseArea {
        id: row
        property string icon
        property string title
        property string detail
        property string trailingIcon: ""
        property bool highlighted: false
        property bool clickable: false

        Layout.fillWidth: true
        implicitHeight: Math.round(Style.fontSize * 2.9)
        hoverEnabled: clickable
        cursorShape: clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: clickable ? Qt.LeftButton : Qt.NoButton

        Rectangle {
            anchors.fill: parent
            radius: Style.radius
            color: row.highlighted ? Theme.surface : row.containsMouse ? Qt.alpha(Theme.surface, 0.5) : "transparent"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Math.round(Style.fontSize * 0.6)
            anchors.rightMargin: Math.round(Style.fontSize * 0.6)
            spacing: Math.round(Style.fontSize * 0.7)

            VIcon {
                icon: row.icon
                color: row.highlighted ? Theme.accent : Theme.text
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                VText {
                    Layout.fillWidth: true
                    text: row.title
                    elide: Text.ElideRight
                    font.bold: row.highlighted
                }
                VText {
                    Layout.fillWidth: true
                    text: row.detail
                    color: Theme.textMuted
                    font.pixelSize: Style.fontSize * 0.82
                    elide: Text.ElideRight
                }
            }
            VIcon {
                visible: row.trailingIcon !== ""
                icon: row.trailingIcon
                color: Theme.textMuted
                size: Style.fontSize
            }
        }
    }
}
