import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Components
import qs.Services

// Grid of the images in the wallpaper folder. Click (or Enter) sets one; the
// picker stays open so you can try others. Type to filter, arrows to move,
// Esc to close.
PanelWindow {
    id: root

    screen: Panels.wallpaperScreen

    WlrLayershell.namespace: "vesper-wallpaper-picker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    // Per-monitor wallpapers: this picker sets its own screen's.
    readonly property bool perMonitor: Settings.wallpaper.sameOnAllMonitors === false && Quickshell.screens.length > 1
    readonly property string screenName: screen ? screen.name : ""
    readonly property string current: WallpaperService.pathFor(perMonitor ? screenName : "")

    property string filter: ""
    readonly property var images: {
        const f = filter.trim().toLowerCase();
        return f === "" ? WallpaperService.images : WallpaperService.images.filter(i => i.name.toLowerCase().includes(f));
    }

    readonly property real cellWidth: Math.round(Style.fontSize * 15)
    readonly property real cellHeight: Math.round(cellWidth * 0.62 + Style.fontSize * 1.8)
    readonly property int columns: 4

    function close() {
        Panels.wallpaperOpen = false;
    }

    function apply(index) {
        const image = images[index];
        if (image)
            WallpaperService.set(image.path, perMonitor ? screenName : "");
    }

    Component.onCompleted: {
        const i = images.findIndex(img => img.path === current);
        grid.currentIndex = Math.max(0, i);
        grid.positionViewAtIndex(grid.currentIndex, GridView.Center);
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(root.cellWidth * root.columns + padding * 2 + 8, parent.width - 40)
        height: Math.min(column.implicitHeight + padding * 2, parent.height - 80)
        readonly property real padding: Math.round(Style.fontSize * 1.1)
        radius: Style.radius * 2
        color: Theme.background
        border.width: 1
        border.color: Theme.border

        opacity: 0
        scale: 0.97
        Component.onCompleted: {
            opacity = 1;
            scale = 1;
        }
        Behavior on opacity { NumberAnimation { duration: Style.animationDuration } }
        Behavior on scale { NumberAnimation { duration: Style.animationDuration; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: card.padding
            spacing: Math.round(Style.fontSize * 0.8)

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(Style.fontSize * 0.6)

                VIcon {
                    icon: "photo"
                    color: Theme.accent
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    VText {
                        text: root.perMonitor ? `Wallpaper for ${root.screenName}` : "Wallpaper"
                        font.bold: true
                        font.pixelSize: Style.fontSize * 1.1
                    }
                    VText {
                        Layout.fillWidth: true
                        text: WallpaperService.directory === "" ? "No folder set"
                            : `${WallpaperService.images.length} images in ${WallpaperService.directory.replace(Quickshell.env("HOME"), "~")}`
                        color: Theme.textMuted
                        font.pixelSize: Style.fontSize * 0.85
                        elide: Text.ElideMiddle
                    }
                }

                // Filter by name.
                Rectangle {
                    implicitWidth: Math.round(Style.fontSize * 14)
                    implicitHeight: Math.round(Style.fontSize * 2.4)
                    radius: Style.radius
                    color: Theme.surface
                    border.width: 1
                    border.color: search.activeFocus ? Theme.accent : Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(Style.fontSize * 0.6)
                        anchors.rightMargin: Math.round(Style.fontSize * 0.6)
                        spacing: Math.round(Style.fontSize * 0.4)

                        VIcon {
                            icon: "search"
                            color: Theme.textMuted
                            size: Math.round(Style.fontSize * 1.1)
                        }
                        T.TextField {
                            id: search
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            focus: true
                            background: null
                            padding: 0
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.text
                            placeholderText: "Filter"
                            placeholderTextColor: Theme.textMuted
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.onAccent
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSize
                            font.weight: Style.fontWeight
                            onTextChanged: {
                                root.filter = text;
                                grid.currentIndex = 0;
                            }
                            Component.onCompleted: forceActiveFocus()

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape)
                                    root.close();
                                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                                    root.apply(grid.currentIndex);
                                else if (event.key === Qt.Key_Right)
                                    grid.moveCurrentIndexRight();
                                else if (event.key === Qt.Key_Left)
                                    grid.moveCurrentIndexLeft();
                                else if (event.key === Qt.Key_Down)
                                    grid.moveCurrentIndexDown();
                                else if (event.key === Qt.Key_Up)
                                    grid.moveCurrentIndexUp();
                                else
                                    return;
                                event.accepted = true;
                            }
                        }
                    }
                }

                VIconButton {
                    iconName: "arrows-shuffle"
                    tooltip: "Random"
                    enabled: WallpaperService.images.length > 1
                    onClicked: WallpaperService.random(root.perMonitor ? root.screenName : "")
                }
                VIconButton {
                    iconName: "settings"
                    tooltip: "Wallpaper settings"
                    onClicked: Panels.openSettingsTab("wallpaper", root.screen)
                }
                VIconButton {
                    iconName: "x"
                    tooltip: "Close"
                    onClicked: root.close()
                }
            }

            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(Math.ceil(count / root.columns), 3) * root.cellHeight
                Layout.fillHeight: true
                visible: count > 0
                clip: true
                model: root.images
                cellWidth: root.cellWidth
                cellHeight: root.cellHeight
                boundsBehavior: Flickable.StopAtBounds
                highlightFollowsCurrentItem: true
                keyNavigationEnabled: false

                T.ScrollBar.vertical: T.ScrollBar {
                    policy: grid.contentHeight > grid.height ? T.ScrollBar.AsNeeded : T.ScrollBar.AlwaysOff
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: Theme.border
                    }
                }

                delegate: MouseArea {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool isCurrent: modelData.path === root.current
                    readonly property bool selected: GridView.isCurrentItem

                    width: root.cellWidth
                    height: root.cellHeight
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        grid.currentIndex = index;
                        root.apply(index);
                    }

                    Rectangle {
                        id: frame
                        x: 4
                        y: 4
                        width: parent.width - 8
                        height: Math.round(width * 0.62)
                        radius: Style.radius
                        color: Theme.surface
                        border.width: cell.isCurrent ? 2 : (cell.selected || cell.containsMouse ? 2 : 0)
                        border.color: cell.isCurrent ? Theme.accent : Theme.border
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: parent.border.width
                            source: WallpaperService.fileUrl(cell.modelData.path)
                            sourceSize.width: Math.round(root.cellWidth * 1.5)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            smooth: true
                        }

                        VIcon {
                            visible: cell.isCurrent
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 6
                            icon: "circle-check"
                            color: Theme.accent
                        }
                    }

                    VText {
                        anchors.top: frame.bottom
                        anchors.topMargin: 3
                        x: 6
                        width: parent.width - 12
                        text: cell.modelData.name
                        color: cell.isCurrent || cell.selected ? Theme.text : Theme.textMuted
                        font.pixelSize: Style.fontSize * 0.82
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            VText {
                visible: grid.count === 0
                Layout.fillWidth: true
                Layout.topMargin: Style.fontSize
                Layout.bottomMargin: Style.fontSize
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: WallpaperService.images.length > 0 ? "No images match."
                    : `No images found in ${WallpaperService.directory || "the wallpaper folder"}. Choose a folder in Settings → Wallpaper.`
                color: Theme.textMuted
            }
        }
    }
}
