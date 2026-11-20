import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Components
import qs.Services

// The settings panel: a floating layer-shell surface centred on the screen.
// Opened and closed through Panels (bar button, bar click action or IPC).
PanelWindow {
    id: root

    screen: Panels.settingsScreen

    property string currentTab: "bar"
    readonly property var tabs: [
        { id: "bar", label: "Bar", icon: "layout-navbar" },
        { id: "widgets", label: "Widgets", icon: "puzzle" },
        { id: "appearance", label: "Appearance", icon: "palette" },
        { id: "general", label: "General", icon: "adjustments-horizontal" }
    ]
    readonly property var currentTabInfo: tabs.find(t => t.id === currentTab) || tabs[0]

    WlrLayershell.namespace: "vesper-settings"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    implicitWidth: Math.min(Math.round(Style.fontSize * 64), screen ? Math.round(screen.width * 0.9) : 900)
    implicitHeight: Math.min(Math.round(Style.fontSize * 50), screen ? Math.round(screen.height * 0.85) : 700)

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: Style.radius * 2
        color: Theme.background
        border.width: 1
        border.color: Theme.border
        focus: true

        Keys.onEscapePressed: Panels.closeSettings()

        RowLayout {
            anchors.fill: parent
            anchors.margins: 1
            spacing: 0

            // Sidebar
            ColumnLayout {
                readonly property real sidebarWidth: Math.round(Style.fontSize * 13)
                Layout.fillHeight: true
                Layout.fillWidth: false
                Layout.preferredWidth: sidebarWidth
                Layout.maximumWidth: sidebarWidth
                Layout.margins: Math.round(Style.fontSize * 0.8)
                spacing: 4

                RowLayout {
                    Layout.bottomMargin: Style.fontSize
                    Layout.leftMargin: Math.round(Style.fontSize * 0.5)
                    Layout.topMargin: Math.round(Style.fontSize * 0.3)
                    spacing: Math.round(Style.fontSize * 0.5)
                    VIcon {
                        icon: "settings"
                        color: Theme.accent
                        size: Style.fontSize * 1.5
                    }
                    VText {
                        text: "Vesper"
                        font.pixelSize: Style.fontSize * 1.25
                        font.bold: true
                    }
                }

                Repeater {
                    model: root.tabs

                    T.AbstractButton {
                        id: tabButton
                        required property var modelData
                        readonly property bool selected: root.currentTab === modelData.id

                        Layout.fillWidth: true
                        implicitHeight: Math.round(Style.fontSize * 2.5)
                        hoverEnabled: true
                        onClicked: root.currentTab = modelData.id

                        background: Rectangle {
                            radius: Style.radius
                            color: tabButton.selected ? Theme.surface : (tabButton.hovered ? Qt.alpha(Theme.surface, 0.5) : "transparent")
                        }
                        contentItem: RowLayout {
                            spacing: Math.round(Style.fontSize * 0.7)
                            VIcon {
                                Layout.leftMargin: Math.round(Style.fontSize * 0.7)
                                icon: tabButton.modelData.icon
                                color: tabButton.selected ? Theme.accent : Theme.textMuted
                            }
                            VText {
                                Layout.fillWidth: true
                                text: tabButton.modelData.label
                                color: tabButton.selected ? Theme.text : Theme.textMuted
                                font.bold: tabButton.selected
                            }
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                }

                Item { Layout.fillHeight: true }

                VText {
                    Layout.fillWidth: true
                    Layout.leftMargin: Math.round(Style.fontSize * 0.5)
                    wrapMode: Text.Wrap
                    text: "Changes apply and save automatically."
                    color: Theme.textMuted
                    font.pixelSize: Style.fontSize * 0.85
                }
            }

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 1
                color: Theme.border
            }

            // Content
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Math.round(Style.fontSize * 1.6)
                    Layout.rightMargin: Math.round(Style.fontSize * 0.8)
                    Layout.topMargin: Math.round(Style.fontSize * 0.8)
                    Layout.bottomMargin: Math.round(Style.fontSize * 0.4)

                    VText {
                        Layout.fillWidth: true
                        text: root.currentTabInfo.label
                        font.pixelSize: Style.fontSize * 1.45
                        font.bold: true
                    }
                    VIconButton {
                        iconName: "x"
                        tooltip: "Close (Esc)"
                        onClicked: Panels.closeSettings()
                    }
                }

                Flickable {
                    id: flick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: page.implicitHeight + Style.fontSize * 3
                    boundsBehavior: Flickable.StopAtBounds

                    T.ScrollBar.vertical: T.ScrollBar {
                        id: scrollBar
                        policy: flick.contentHeight > flick.height ? T.ScrollBar.AlwaysOn : T.ScrollBar.AlwaysOff
                        contentItem: Rectangle {
                            implicitWidth: 6
                            radius: 3
                            color: scrollBar.pressed ? Theme.textMuted : Theme.border
                        }
                    }

                    Loader {
                        id: page
                        x: Math.round(Style.fontSize * 1.6)
                        y: Math.round(Style.fontSize * 0.8)
                        width: flick.width - x * 2
                        sourceComponent: ({ bar: barTab, widgets: widgetsTab, appearance: appearanceTab, general: generalTab })[root.currentTab]
                        onLoaded: flick.contentY = 0
                    }
                }
            }
        }
    }

    Component { id: barTab; BarTab {} }
    Component { id: widgetsTab; WidgetsTab {} }
    Component { id: appearanceTab; AppearanceTab {} }
    Component { id: generalTab; GeneralTab {} }
}
