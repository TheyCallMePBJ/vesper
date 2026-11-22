import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.Commons
import qs.Components
import qs.Services

// Icon and title of the focused window. Only the icon on vertical bars.
BarWidget {
    id: root

    readonly property var toplevel: HyprlandService.activeToplevel
    readonly property string appId: toplevel && toplevel.wayland ? (toplevel.wayland.appId || "") : ""
    readonly property string title: toplevel ? (toplevel.title || appId) : ""
    readonly property string iconSource: AppIcons.forApp(appId)

    readonly property bool showIcon: root.options.showIcon && iconSource !== ""
    readonly property bool showTitle: !root.vertical && root.options.showTitle

    shown: title !== "" && (showIcon || showTitle)
    implicitWidth: shown ? (root.vertical ? root.barThickness * 0.8 : row.implicitWidth) : 0
    implicitHeight: shown ? root.barThickness * 0.8 : 0

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(root.fontSize * 0.45)

        IconImage {
            visible: root.showIcon
            anchors.verticalCenter: parent.verticalCenter
            source: root.iconSource
            implicitSize: Style.barIconSize(root.fontSize)
            asynchronous: true
        }

        VText {
            visible: root.showTitle
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            font.pixelSize: root.fontSize
            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.options.maxWidth)
        }
    }
}
