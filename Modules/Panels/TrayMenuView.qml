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
//
// Keys: Up/Down (Tab, Ctrl+J/K/N/P) move, Enter/Space choose, Right opens a
// submenu, Left/Backspace/Esc go back. An entry's access letter (the one the
// app underlines) chooses it; other letters jump to entries starting with them.
ColumnLayout {
    id: root

    required property var item
    // Taller menus scroll.
    property real maxHeight: 600
    signal done()
    // Left/Backspace at the top level (the drop-down goes back to its icons).
    signal backAtTop()

    // Entries whose submenus were opened, innermost last, and the selected
    // row in each parent, to return to.
    property var stack: []
    property var returnIndex: []

    // Selected row (index into `targets`), -1 for none. Shared by mouse and
    // keyboard.
    property int current: -1
    property bool usingKeys: false

    spacing: 1
    focus: true

    // DBusMenu labels mark mnemonics with "_" ("__" is a real underscore).
    function label(text) {
        return String(text || "").replace(/__|_/g, m => m === "__" ? "_" : "");
    }
    function mnemonic(text) {
        const m = String(text || "").replace(/__/g, "").match(/_(.)/);
        return m ? m[1].toLowerCase() : "";
    }

    readonly property bool showPin: TrayService.drawerInUse && stack.length === 0
    // The rows you can select: enabled entries, then "Pin to bar".
    readonly property var targets: entryList.filter(e => !e.isSeparator && e.enabled).concat(showPin ? ["pin"] : [])

    function choose(target) {
        if (target === "pin") {
            TrayService.setPinned(root.item, !TrayService.isPinned(root.item));
            root.done();
        } else if (target.hasChildren) {
            openSubmenu(target);
        } else {
            target.triggered();
            root.done();
        }
    }
    function openSubmenu(entry) {
        returnIndex = returnIndex.concat([current]);
        stack = stack.concat([entry]);
        current = usingKeys ? 0 : -1;
    }
    function goBack() {
        if (stack.length === 0)
            return false;
        const back = returnIndex[returnIndex.length - 1];
        stack = stack.slice(0, -1);
        returnIndex = returnIndex.slice(0, -1);
        current = usingKeys ? back : -1;
        return true;
    }
    function move(delta) {
        usingKeys = true;
        const n = targets.length;
        if (n === 0)
            return;
        current = current < 0 ? (delta > 0 ? 0 : n - 1) : (current + delta + n) % n;
    }

    onTargetsChanged: if (current >= targets.length) current = targets.length - 1
    onCurrentChanged: Qt.callLater(scrollToCurrent)
    function scrollToCurrent() {
        const t = targets[current];
        if (!t || t === "pin")
            return;
        for (let i = 0; i < rowRepeater.count; i++) {
            const r = rowRepeater.itemAt(i);
            if (r && r.modelData === t) {
                if (r.y < list.contentY)
                    list.contentY = r.y;
                else if (r.y + r.height > list.contentY + list.height)
                    list.contentY = r.y + r.height - list.height;
                return;
            }
        }
    }

    Keys.onPressed: event => {
        const ctrl = event.modifiers & Qt.ControlModifier;
        const k = event.key;
        if (k === Qt.Key_Down || k === Qt.Key_Tab || (ctrl && (k === Qt.Key_J || k === Qt.Key_N))) {
            move(1);
        } else if (k === Qt.Key_Up || k === Qt.Key_Backtab || (ctrl && (k === Qt.Key_K || k === Qt.Key_P))) {
            move(-1);
        } else if (k === Qt.Key_Home) {
            usingKeys = true;
            current = targets.length > 0 ? 0 : -1;
        } else if (k === Qt.Key_End) {
            usingKeys = true;
            current = targets.length - 1;
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
            usingKeys = true;
            if (current >= 0)
                choose(targets[current]);
        } else if (k === Qt.Key_Right) {
            usingKeys = true;
            const t = targets[current];
            if (t && t !== "pin" && t.hasChildren)
                openSubmenu(t);
        } else if (k === Qt.Key_Left || k === Qt.Key_Backspace) {
            usingKeys = true;
            if (!goBack())
                backAtTop();
        } else if (k === Qt.Key_Escape) {
            // At the top level, let the panel close.
            usingKeys = true;
            if (!goBack())
                return;
        } else if (!ctrl && event.text.length === 1 && /\S/.test(event.text)) {
            usingKeys = true;
            const c = event.text.toLowerCase();
            const entries = targets.filter(t => t !== "pin");
            const hit = entries.find(e => mnemonic(e.text) === c);
            if (hit) {
                current = targets.indexOf(hit);
                choose(hit);
            } else {
                // Next entry (after the selected one) whose label starts with it.
                const n = targets.length;
                for (let i = 1; i <= n; i++) {
                    const j = (Math.max(current, -1) + i) % n;
                    const t = targets[j];
                    const text = t === "pin" ? (TrayService.isPinned(root.item) ? "unpin" : "pin") : label(t.text);
                    if (text.toLowerCase().startsWith(c)) {
                        current = j;
                        break;
                    }
                }
            }
        } else {
            return;
        }
        event.accepted = true;
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
        onClicked: root.goBack()

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
                id: rowRepeater
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
                            navIndex: root.targets.indexOf(e)
                            text: root.label(e.text)
                            iconSource: e.icon || ""
                            enabled: e.enabled
                            checkable: e.buttonType !== QsMenuButtonType.None
                            radio: e.buttonType === QsMenuButtonType.RadioButton
                            checked: e.checkState === Qt.Checked
                            submenu: e.hasChildren
                            onClicked: root.choose(e)
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
        visible: root.showPin
        Layout.fillWidth: true
        readonly property bool pinned: TrayService.isPinned(root.item)
        navIndex: root.targets.indexOf("pin")
        text: pinned ? "Unpin from bar" : "Pin to bar"
        tablerIcon: pinned ? "pinned-off" : "pin"
        onClicked: root.choose("pin")
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
        property int navIndex: -1
        readonly property bool selected: navIndex >= 0 && root.current === navIndex

        // Hovering selects the row; leaving clears it (unless the keys moved on).
        onContainsMouseChanged: {
            if (containsMouse && enabled) {
                root.usingKeys = false;
                root.current = navIndex;
            } else if (!containsMouse && !root.usingKeys && root.current === navIndex) {
                root.current = -1;
            }
        }

        implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin * 2
        implicitHeight: Math.round(Style.fontSize * 1.85)
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        opacity: enabled ? 1 : 0.4

        Rectangle {
            anchors.fill: parent
            radius: Style.radius
            color: menuRow.pressed ? Theme.surfaceAlt : Theme.surface
            visible: menuRow.enabled && menuRow.selected
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
