import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services
// Not used directly: widgets are loaded by URL from WidgetRegistry. Importing
// the folder makes Quickshell scan it so the qs.* modules widgets use exist.
import qs.Widgets

// Creates one bar widget from its settings entry ({ type, ...options }) and
// keeps its properties in sync with the bar.
Loader {
    id: root

    required property var modelData   // the settings entry
    property ShellScreen screen: null
    property bool vertical: false
    property real barThickness: 30
    property real fontSize: 13

    readonly property string type: modelData && modelData.type ? modelData.type : ""
    readonly property bool known: WidgetRegistry.has(type)

    active: known
    visible: known && status === Loader.Ready && !!item && item.shown !== false
    Layout.alignment: Qt.AlignCenter
    source: known ? WidgetRegistry.url(type) : ""
    asynchronous: false

    Component.onCompleted: if (!known) WidgetRegistry.warnUnknown(type)

    onStatusChanged: if (status === Loader.Error) Logger.e("Widgets", `Failed to load widget "${type}"`)

    Binding { target: root.item; property: "options"; value: WidgetRegistry.resolveOptions(root.modelData); when: root.status === Loader.Ready }
    Binding { target: root.item; property: "screen"; value: root.screen; when: root.status === Loader.Ready }
    Binding { target: root.item; property: "vertical"; value: root.vertical; when: root.status === Loader.Ready }
    Binding { target: root.item; property: "barThickness"; value: root.barThickness; when: root.status === Loader.Ready }
    Binding { target: root.item; property: "fontSize"; value: root.fontSize; when: root.status === Loader.Ready }
}
