import QtQuick
import Quickshell
import qs.Services

// Base type for bar widgets. BarWidgetLoader sets these properties; widgets
// only need to set their implicit size and draw themselves.
Item {
    id: widget

    // Merged options for this instance (defaults + what's in settings.json).
    property var options: ({})
    property ShellScreen screen: null
    property bool vertical: false
    // Height of a horizontal bar / width of a vertical one.
    property real barThickness: 30
    property real fontSize: 13
    // Set false to hide the widget entirely (e.g. no battery present). The bar
    // then gives it no space or spacing. Use this rather than `visible`.
    property bool shown: true

    // Set to the bar panel this widget opens ("calendar", "audio", ...), so
    // IPC can open that panel next to it. togglePanel() opens or closes it.
    property string panelName: ""
    readonly property bool panelOpen: panelName !== "" && Panels.panel === panelName && Panels.panelAnchor === widget

    function togglePanel() {
        Panels.togglePanel(panelName, widget);
    }

    visible: shown

    Component.onCompleted: if (panelName !== "") Panels.registerAnchor(panelName, widget)
    Component.onDestruction: Panels.unregisterAnchor(widget)
}
