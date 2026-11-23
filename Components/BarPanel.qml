import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services

// A panel that drops out of the bar next to the widget that opened it
// (calendar, audio, notifications, control center). Covers the screen apart
// from the bar with an invisible layer, so a click anywhere outside the card
// closes it, and clicks on the bar still reach its widgets. Esc closes too.
//
// Children go into a ColumnLayout `panelWidth` wide; the card's height follows
// their implicit height.
PanelWindow {
    id: root

    property real panelWidth: Math.round(Style.fontSize * 24)
    // Where to put the panel when nothing anchors it: start | center | end
    property string defaultAlign: "end"
    property real padding: Math.round(Style.fontSize * 1.1)
    // Space between the panel's children.
    property real contentSpacing: Math.round(Style.fontSize * 0.8)
    default property alias content: column.data

    readonly property var barConfig: Settings.barFor(screen ? screen.name : "")
    readonly property string barPosition: ["top", "bottom", "left", "right"].includes(barConfig.position) ? barConfig.position : "top"
    readonly property bool barVertical: barPosition === "left" || barPosition === "right"
    readonly property real gap: 6

    // Centre of the anchor widget along the bar, in screen coordinates,
    // worked out once when the panel opens.
    property real anchorPos: -1

    screen: Panels.panelScreen

    WlrLayershell.namespace: "vesper-panel"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Normal
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    function updateAnchor() {
        const item = Panels.panelAnchor;
        if (item) {
            const p = item.mapToItem(null, item.width / 2, item.height / 2);
            anchorPos = barVertical ? p.y : p.x;
        } else {
            anchorPos = -1;
        }
    }

    Component.onCompleted: {
        updateAnchor();
        card.opacity = 1;
        card.shift = 0;
    }

    // Another widget took the panel over.
    Connections {
        target: Panels
        function onPanelAnchorChanged() {
            if (Panels.panelAnchor)
                root.updateAnchor();
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: Panels.closePanel()
    }

    Rectangle {
        id: card

        // Slides in from the bar.
        property real shift: -Math.round(Style.fontSize * 0.8)
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: Style.animationDuration } }
        Behavior on shift { NumberAnimation { duration: Style.animationDuration * 1.3; easing.type: Easing.OutCubic } }

        readonly property real span: root.barVertical ? root.height : root.width
        readonly property real length: root.barVertical ? height : width
        readonly property real along: {
            const max = span - length - root.gap;
            let pos;
            if (root.anchorPos >= 0)
                pos = root.anchorPos - length / 2;
            else if (root.defaultAlign === "start")
                pos = root.gap;
            else if (root.defaultAlign === "center")
                pos = (span - length) / 2;
            else
                pos = max;
            return Math.round(Math.max(root.gap, Math.min(max, pos)));
        }

        width: root.panelWidth
        height: column.implicitHeight + root.padding * 2
        x: root.barVertical ? (root.barPosition === "left" ? root.gap + shift : root.width - width - root.gap - shift) : along
        y: root.barVertical ? along : (root.barPosition === "top" ? root.gap + shift : root.height - height - root.gap - shift)

        radius: Style.radius * 2
        color: Theme.background
        border.width: 1
        border.color: Theme.border

        focus: true
        Keys.onEscapePressed: Panels.closePanel()

        // Clicks on the card itself don't close it.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        ColumnLayout {
            id: column
            x: root.padding
            y: root.padding
            width: parent.width - root.padding * 2
            spacing: root.contentSpacing
        }
    }
}
