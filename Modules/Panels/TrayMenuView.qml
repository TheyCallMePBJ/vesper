import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Components
import qs.Services

// A tray app's menu, drawn in Vesper's style. Submenus open in place, with a
// row at the top to go back. Ends with "Pin to bar" when the tray is a
// drop-down. Emits done() after an entry is chosen.
ColumnLayout {
    id: root

    required property var item
    // Taller menus scroll.
    property real maxHeight: 600
    signal done()

    // Entries whose submenus were opened, innermost last.
    property var stack: []

    spacing: 1

    // DBusMenu labels mark mnemonics with "_" ("__" is a real underscore).
    function label(text) {
        return String(text || "").replace(/__|_/g, m => m === "__" ? "_" : "");
    }

    // One opener per level, so parent menus stay loaded while a submenu shows
    // (a submenu's entries don't load once its parent is let go).
    QsMenuOpener {
        id: rootOpener
        menu: root.item ? root.item.menu : null
    }
    Instantiator {
        id: subOpeners
        model: root.stack
        delegate: QsMenuOpener {
            required property var modelData
            menu: modelData
        }
    }
    readonly property var opener: root.stack.length > 0 && subOpeners.count === root.stack.length
        ? subOpeners.objectAt(root.stack.length - 1) : rootOpener

    // Header: the app's name, or the submenu's with a back arrow.
    MouseArea {
        id: header
        Layout.fillWidth: true
        implicitWidth: headerRow.implicitWidth + headerRow.anchors.leftMargin * 2
        implicitHeight: Math.round(Style.fontSize * 1.75)
        enabled: root.stack.length > 0
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.stack = root.stack.slice(0, -1)

        Rectangle {
            anchors.fill: parent
            radius: Style.radius
            color: Theme.surface
            visible: header.enabled && header.containsMouse
        }

        RowLayout {
            id: headerRow
            anchors.fill: parent
            anchors.leftMargin: Math.round(Style.fontSize * 0.45)
            anchors.rightMargin: Math.round(Style.fontSize * 0.45)
            spacing: Math.round(Style.fontSize * 0.45)

            VIcon {
                visible: root.stack.length > 0
                icon: "chevron-left"
                color: Theme.textMuted
                size: Math.round(Style.fontSize * 1.1)
            }
            IconImage {
                visible: root.stack.length === 0 && !!root.item && status === Image.Ready
                source: root.item ? root.item.icon : ""
                implicitSize: Math.round(Style.fontSize * 1.05)
                asynchronous: true
            }
            VText {
                Layout.fillWidth: true
                Layout.maximumWidth: Math.round(Style.fontSize * 16)
                text: root.stack.length > 0 ? root.label(root.stack[root.stack.length - 1].text)
                    : root.item ? (root.item.tooltipTitle || root.item.title || root.item.id) : ""
                color: Theme.textMuted
                font.pixelSize: Style.fontSize * 0.85
                font.bold: true
                elide: Text.ElideRight
            }
        }
    }

    // The entries; scrolls if the menu is taller than `maxHeight`.
    Flickable {
        id: list
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(entries.implicitHeight, root.maxHeight)
        implicitWidth: entries.implicitWidth
        contentHeight: entries.implicitHeight
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: entries
            width: list.width
            spacing: 1

            Repeater {
                model: root.opener ? root.opener.children : null

                Loader {
                    id: row
                    required property var modelData
                    Layout.fillWidth: true
                    // Entries can arrive after the menu opens; this keeps the
                    // menu's width following them.
                    Layout.preferredWidth: item ? item.implicitWidth : 0
                    sourceComponent: modelData.isSeparator ? separator : entry

                    Component {
                        id: separator
                        Item {
                            implicitHeight: Math.round(Style.fontSize * 0.5)
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.round(Style.fontSize * 0.45)
                                width: parent.width - x * 2
                                height: 1
                                color: Theme.border
                            }
                        }
                    }

                    Component {
                        id: entry
                        MenuRow {
                            readonly property var e: row.modelData
                            text: root.label(e.text)
                            iconSource: e.icon || ""
                            enabled: e.enabled
                            checkable: e.buttonType !== QsMenuButtonType.None
                            radio: e.buttonType === QsMenuButtonType.RadioButton
                            checked: e.checkState === Qt.Checked
                            submenu: e.hasChildren
                            onClicked: {
                                if (e.hasChildren) {
                                    root.stack = root.stack.concat([e]);
                                } else {
                                    e.triggered();
                                    root.done();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    VText {
        visible: root.entryList.length === 0
        Layout.fillWidth: true
        Layout.margins: Math.round(Style.fontSize * 0.5)
        text: "This app's menu is empty."
        color: Theme.textMuted
        font.pixelSize: Style.fontSize * 0.9
    }

    // Pinning, for drop-down trays. (No extra line if the app's menu already
    // ends with one.)
    readonly property var entryList: root.opener ? root.opener.children.values : []
    Rectangle {
        visible: TrayService.drawerInUse && root.stack.length === 0
                 && !(root.entryList.length > 0 && root.entryList[root.entryList.length - 1].isSeparator)
        Layout.fillWidth: true
        Layout.topMargin: Math.round(Style.fontSize * 0.25)
        Layout.bottomMargin: Math.round(Style.fontSize * 0.25)
        Layout.leftMargin: Math.round(Style.fontSize * 0.45)
        Layout.rightMargin: Math.round(Style.fontSize * 0.45)
        implicitHeight: 1
        color: Theme.border
    }
    MenuRow {
        visible: TrayService.drawerInUse && root.stack.length === 0
        Layout.fillWidth: true
        readonly property bool pinned: TrayService.isPinned(root.item)
        text: pinned ? "Unpin from bar" : "Pin to bar"
        tablerIcon: pinned ? "pinned-off" : "pin"
        onClicked: {
            TrayService.setPinned(root.item, !pinned);
            root.done();
        }
    }

    component MenuRow: MouseArea {
        id: menuRow
        property string text: ""
        property string iconSource: ""
        property string tablerIcon: ""
        property bool checkable: false
        property bool radio: false
        property bool checked: false
        property bool submenu: false

        implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin * 2
        implicitHeight: Math.round(Style.fontSize * 1.85)
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        opacity: enabled ? 1 : 0.4

        Rectangle {
            anchors.fill: parent
            radius: Style.radius
            color: menuRow.pressed ? Theme.surfaceAlt : Theme.surface
            visible: menuRow.enabled && menuRow.containsMouse
        }

        RowLayout {
            id: rowLayout
            anchors.fill: parent
            anchors.leftMargin: Math.round(Style.fontSize * 0.45)
            anchors.rightMargin: Math.round(Style.fontSize * 0.45)
            spacing: Math.round(Style.fontSize * 0.5)

            // Check mark, radio dot, the entry's own icon, or empty space so
            // labels line up.
            Item {
                implicitWidth: Math.round(Style.fontSize * 1.05)
                implicitHeight: implicitWidth

                VIcon {
                    anchors.centerIn: parent
                    visible: menuRow.checkable || menuRow.tablerIcon !== ""
                    icon: menuRow.tablerIcon !== "" ? menuRow.tablerIcon
                        : menuRow.radio ? (menuRow.checked ? "circle-dot" : "circle")
                        : (menuRow.checked ? "square-check" : "square")
                    color: menuRow.checked ? Theme.accent : Theme.textMuted
                    size: Math.round(Style.fontSize * 1.05)
                }
                IconImage {
                    anchors.fill: parent
                    visible: !menuRow.checkable && menuRow.tablerIcon === "" && menuRow.iconSource !== "" && status === Image.Ready
                    source: menuRow.iconSource
                    asynchronous: true
                }
            }

            VText {
                Layout.fillWidth: true
                Layout.maximumWidth: Math.round(Style.fontSize * 18)
                text: menuRow.text
                elide: Text.ElideRight
            }

            VIcon {
                visible: menuRow.submenu
                icon: "chevron-right"
                color: Theme.textMuted
                size: Math.round(Style.fontSize)
            }
        }
    }
}
