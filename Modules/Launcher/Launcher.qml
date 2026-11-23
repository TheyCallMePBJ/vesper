import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Components
import qs.Services

// App launcher with a calculator: type to search apps, or a sum / conversion
// ("2^10", "10 km to mi", "100 usd to eur") to see the result first.
// Keys: Up/Down (or Tab, Ctrl+J/K) to move, Enter to launch or copy the
// result, Esc to close.
PanelWindow {
    id: root

    screen: Panels.launcherScreen

    WlrLayershell.namespace: "vesper-launcher"
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

    property string query: ""
    readonly property var calcResult: LauncherService.calculate(query)
    readonly property var apps: LauncherService.search(query)
    // Rows: an optional calculator result, then apps.
    readonly property var results: (calcResult ? [{ type: "calc", result: calcResult }] : []).concat(apps.map(e => ({ type: "app", entry: e })))

    readonly property real rowHeight: Math.round(Style.fontSize * 3.3)
    readonly property int visibleRows: 8

    function close() {
        Panels.launcherOpen = false;
    }

    function activate(index) {
        const item = results[index];
        if (!item)
            return;
        if (item.type === "calc") {
            if (item.result.text !== "")
                LauncherService.copy(item.result.text.replace(/,/g, ""));
        } else {
            LauncherService.launch(item.entry);
        }
        close();
    }

    function move(delta) {
        if (results.length === 0)
            return;
        list.currentIndex = Math.max(0, Math.min(results.length - 1, list.currentIndex + delta));
    }

    onResultsChanged: list.currentIndex = 0

    // Click outside the card closes.
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        // Where a full list (all rows showing) would be centred. The search box
        // stays put as the results change; fewer results just end higher up.
        y: Math.max(20, Math.round((parent.height - fullHeight) / 2))
        readonly property real fullHeight: padding * 2 + Math.round(Style.fontSize * 2.9) + Math.round(Style.fontSize * 0.6) + root.visibleRows * root.rowHeight
        width: Math.min(Math.round(Style.fontSize * 38), parent.width - 40)
        height: column.implicitHeight + padding * 2
        readonly property real padding: Math.round(Style.fontSize * 0.9)
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
            x: card.padding
            y: card.padding
            width: card.width - card.padding * 2
            spacing: Math.round(Style.fontSize * 0.6)

            // Search box.
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.round(Style.fontSize * 2.9)
                radius: Style.radius
                color: Theme.surface
                border.width: 1
                border.color: search.activeFocus ? Theme.accent : Theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(Style.fontSize * 0.8)
                    anchors.rightMargin: Math.round(Style.fontSize * 0.8)
                    spacing: Math.round(Style.fontSize * 0.6)

                    VIcon {
                        icon: "search"
                        color: Theme.textMuted
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
                        placeholderText: Settings.launcher.calculator ? "Search apps, or type a sum or conversion" : "Search apps"
                        placeholderTextColor: Theme.textMuted
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.onAccent
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSize * 1.15
                        font.weight: Style.fontWeight
                        onTextChanged: root.query = text

                        Component.onCompleted: {
                            text = Panels.launcherQuery;
                            forceActiveFocus();
                        }

                        Keys.onPressed: event => {
                            const ctrl = event.modifiers & Qt.ControlModifier;
                            if (event.key === Qt.Key_Escape) {
                                root.close();
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.activate(list.currentIndex);
                            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
                                root.move(1);
                            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
                                root.move(-1);
                            } else if (event.key === Qt.Key_PageDown) {
                                root.move(root.visibleRows);
                            } else if (event.key === Qt.Key_PageUp) {
                                root.move(-root.visibleRows);
                            } else {
                                return;
                            }
                            event.accepted = true;
                        }
                    }
                }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(count, root.visibleRows) * root.rowHeight
                visible: count > 0
                clip: true
                model: root.results
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: 0
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                T.ScrollBar.vertical: T.ScrollBar {
                    policy: list.contentHeight > list.height ? T.ScrollBar.AsNeeded : T.ScrollBar.AlwaysOff
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: Theme.border
                    }
                }

                delegate: MouseArea {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool selected: ListView.isCurrentItem
                    readonly property bool isCalc: modelData.type === "calc"

                    width: list.width
                    height: root.rowHeight
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: list.currentIndex = index
                    onClicked: root.activate(index)

                    Rectangle {
                        anchors.fill: parent
                        anchors.rightMargin: 6
                        radius: Style.radius
                        color: row.selected ? Theme.surface : "transparent"
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(Style.fontSize * 0.7)
                        anchors.rightMargin: Math.round(Style.fontSize * 0.7) + 6
                        spacing: Math.round(Style.fontSize * 0.8)

                        Item {
                            implicitWidth: Math.round(Style.fontSize * 2.1)
                            implicitHeight: implicitWidth

                            IconImage {
                                id: appIcon
                                anchors.fill: parent
                                visible: !row.isCalc && status === Image.Ready
                                source: row.isCalc ? "" : Quickshell.iconPath(row.modelData.entry.icon || "", true)
                                asynchronous: true
                            }
                            VIcon {
                                anchors.centerIn: parent
                                visible: row.isCalc || !appIcon.visible
                                icon: !row.isCalc ? "app-window"
                                    : row.modelData.result.kind === "currency" ? "currency"
                                    : row.modelData.result.kind === "unit" ? "arrows-exchange" : "calculator"
                                color: row.isCalc ? Theme.accent : Theme.textMuted
                                size: Math.round(Style.fontSize * 1.6)
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            VText {
                                Layout.fillWidth: true
                                text: {
                                    if (!row.isCalc)
                                        return row.modelData.entry.name;
                                    const r = row.modelData.result;
                                    if (r.needsRates)
                                        return LauncherService.ratesError || "Getting exchange rates...";
                                    return r.text;
                                }
                                font.pixelSize: row.isCalc ? Style.fontSize * 1.25 : Style.fontSize
                                font.weight: row.isCalc ? Font.Bold : Style.fontWeight
                                color: row.isCalc && row.modelData.result.needsRates ? Theme.textMuted : Theme.text
                                elide: Text.ElideRight
                            }
                            VText {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: {
                                    if (row.isCalc) {
                                        const r = row.modelData.result;
                                        if (r.kind === "currency" && r.date)
                                            return `${r.detail.replace(/ =$/, "")} · rates from ${Qt.formatDate(new Date(r.date + "T12:00:00"), "d MMM yyyy")}`;
                                        return r.detail;
                                    }
                                    const e = row.modelData.entry;
                                    return e.comment || e.genericName || "";
                                }
                                color: Theme.textMuted
                                font.pixelSize: Style.fontSize * 0.85
                                elide: Text.ElideRight
                            }
                        }

                        VText {
                            visible: row.selected
                            text: row.isCalc ? (row.modelData.result.text !== "" ? "Enter to copy" : "") : "Enter"
                            color: Theme.textMuted
                            font.pixelSize: Style.fontSize * 0.8
                        }
                    }
                }
            }

            VText {
                visible: root.results.length === 0
                Layout.fillWidth: true
                Layout.topMargin: Math.round(Style.fontSize * 0.3)
                Layout.bottomMargin: Math.round(Style.fontSize * 0.3)
                horizontalAlignment: Text.AlignHCenter
                text: "Nothing found"
                color: Theme.textMuted
            }
        }
    }
}
