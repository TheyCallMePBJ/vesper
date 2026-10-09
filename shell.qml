import Quickshell
import Quickshell.Wayland
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
