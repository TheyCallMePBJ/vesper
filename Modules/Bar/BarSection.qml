import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Components

// One of the bar's left / center / right sections. Lays its widgets out in a
// row (horizontal bar) or a column (vertical bar).
LineLayout {
    id: root

    property var entries: []
    property ShellScreen screen: null
    property real barThickness: 30
    property real fontSize: 13

    Repeater {
        model: root.entries

        BarWidgetLoader {
            screen: root.screen
            vertical: root.vertical
            barThickness: root.barThickness
            fontSize: root.fontSize
        }
    }
}
