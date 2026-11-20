import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

ShellRoot {
    Scope {
        // Automatically create a bar for every connected screen
        Variants {
            model: Quickshell.screens

            PanelWindow {
                required property var modelData
                screen: modelData

                // Bar positioning and dimensions
                anchors {
                    top: true
                    left: true
                    right: true
                }
                implicitHeight: 24
                color: Qt.rgba(0.10, 0.11, 0.13, 0.65)

                // System clock source
                SystemClock {
                    id: sysClock
                    precision: SystemClock.Seconds
                }

                // Workspace indicators (top left)
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Repeater {
                        model: Hyprland.workspaces

                        Text {
                            required property HyprlandWorkspace modelData
                            readonly property bool isFocused: Hyprland.focusedWorkspace?.id === modelData.id

                            // Skip special (scratchpad) workspaces, which have negative ids
                            visible: modelData.id > 0
                            text: modelData.name
                            color: isFocused ? Qt.rgba(0.94, 0.94, 0.92, 1) : Qt.rgba(0.94, 0.94, 0.92, 0.5)
                            font.pixelSize: 12
                            font.bold: isFocused

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.activate()
                            }
                        }
                    }
                }

                // Centered time display
                Text {
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(sysClock.date, "hh:mm - dd/MM")
                    color: Qt.rgba(0.94, 0.94, 0.92, 1)
                    font.pixelSize: 12
                }
            }
        }
    }
}
