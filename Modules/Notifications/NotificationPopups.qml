import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services

// Notification popups in a corner of one screen: the configured monitor, or
// the focused one when the first popup appears. Hovering a popup pauses its
// timeout.
Scope {
    id: root

    readonly property bool hasPopups: NotificationService.popups.length > 0
    property ShellScreen screen: null

    function pickScreen() {
        const wanted = Settings.notifications.monitor;
        screen = Quickshell.screens.find(s => s.name === wanted) || Panels.focusedScreen();
    }

    onHasPopupsChanged: if (hasPopups) pickScreen()

    LazyLoader {
        active: root.hasPopups && root.screen !== null

        PanelWindow {
            id: win

            readonly property string position: Settings.notifications.position || "top-right"
            readonly property bool atBottom: position.startsWith("bottom")
            readonly property real margin: Math.round(Style.fontSize * 0.8)

            screen: root.screen
            WlrLayershell.namespace: "vesper-notifications"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 0
            color: "transparent"

            anchors {
                top: !atBottom
                bottom: atBottom
                left: position.endsWith("left")
                right: position.endsWith("right")
            }
            margins {
                top: margin
                bottom: margin
                left: margin
                right: margin
            }

            implicitWidth: Math.round(Style.fontSize * 28)
            implicitHeight: column.implicitHeight

            ColumnLayout {
                id: column
                width: parent.width
                spacing: Math.round(Style.fontSize * 0.6)

                Repeater {
                    // Newest nearest the screen edge.
                    model: ScriptModel {
                        values: win.atBottom ? NotificationService.popups.slice().reverse() : NotificationService.popups
                    }

                    NotificationCard {
                        id: card
                        required property NotificationEntry modelData
                        entry: modelData
                        popup: true
                        Layout.fillWidth: true

                        readonly property real timeout: NotificationService.timeoutFor(modelData)

                        // Slide in from the side.
                        opacity: 0
                        transform: Translate {
                            id: slide
                            x: win.position.endsWith("left") ? -40 : 40
                            Behavior on x { NumberAnimation { duration: Style.animationDuration * 1.5; easing.type: Easing.OutCubic } }
                        }
                        Component.onCompleted: {
                            opacity = 1;
                            slide.x = 0;
                        }
                        Behavior on opacity { NumberAnimation { duration: Style.animationDuration } }

                        // Hovering pauses it (and starts it over).
                        Timer {
                            id: timer
                            interval: card.timeout * 1000
                            running: card.timeout > 0 && !card.hovered
                            onTriggered: NotificationService.hidePopup(card.modelData)
                        }

                        Connections {
                            target: NotificationService
                            function onPopupUpdated(entry) {
                                if (entry === card.modelData)
                                    timer.restart();
                            }
                        }
                    }
                }
            }
        }
    }
}
