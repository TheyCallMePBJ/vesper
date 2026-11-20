import QtQuick
import Quickshell

// Base type for bar widgets. BarWidgetLoader sets these properties; widgets
// only need to set their implicit size and draw themselves.
Item {
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

    visible: shown
}
