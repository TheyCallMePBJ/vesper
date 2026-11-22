import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services

// The bar for one screen.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData

    readonly property var config: Settings.barFor(modelData.name)
    readonly property string position: ["top", "bottom", "left", "right"].includes(config.position) ? config.position : "top"
    readonly property bool vertical: position === "left" || position === "right"
    readonly property real thickness: Style.barThickness(config.height)
    readonly property real fontSize: Style.barFontSize(config.contentScale)
    readonly property var widgets: config.widgets || ({})

    WlrLayershell.namespace: "vesper-bar"

    // Keep awake: any bar's surface can hold the inhibitor.
    IdleInhibitor {
        window: root
        enabled: KeepAwakeService.enabled
    }

    anchors {
        top: root.position !== "bottom"
        bottom: root.position !== "top"
        left: root.position !== "right"
        right: root.position !== "left"
    }
    implicitHeight: vertical ? 0 : thickness
    implicitWidth: vertical ? thickness : 0
    exclusiveZone: thickness

    color: Qt.alpha(Theme.background, Math.max(0, Math.min(1, config.backgroundOpacity)))

    // Catches scroll and right/middle clicks on any part of the bar the
    // widgets themselves don't handle.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => BarActions.handleClick(mouse.button === Qt.RightButton ? root.config.actions.rightClick : root.config.actions.middleClick, root.modelData)
        onWheel: wheel => BarActions.handleWheel(root.config, wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x, root.modelData)

        BarSection {
            id: startSection
            entries: root.widgets.left || []
            screen: root.modelData
            vertical: root.vertical
            barThickness: root.thickness
            fontSize: root.fontSize
            spacing: root.config.widgetSpacing

            x: root.vertical ? Math.round((parent.width - width) / 2) : root.config.padding
            y: root.vertical ? root.config.padding : Math.round((parent.height - height) / 2)
        }

        BarSection {
            id: centerSection
            entries: root.widgets.center || []
            screen: root.modelData
            vertical: root.vertical
            barThickness: root.thickness
            fontSize: root.fontSize
            spacing: root.config.widgetSpacing

            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
        }

        BarSection {
            id: endSection
            entries: root.widgets.right || []
            screen: root.modelData
            vertical: root.vertical
            barThickness: root.thickness
            fontSize: root.fontSize
            spacing: root.config.widgetSpacing

            x: root.vertical ? Math.round((parent.width - width) / 2) : parent.width - width - root.config.padding
            y: root.vertical ? parent.height - height - root.config.padding : Math.round((parent.height - height) / 2)
        }
    }
}
