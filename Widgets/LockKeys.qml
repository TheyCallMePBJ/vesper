import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Components
import qs.Services

// Caps / Num / Scroll Lock indicators: highlighted when on.
BarWidget {
    id: root

    readonly property var keys: [
        { show: root.options.showCaps, on: KeyboardService.capsLock, label: "Caps", short: "A" },
        { show: root.options.showNum, on: KeyboardService.numLock, label: "Num", short: "1" },
        { show: root.options.showScroll, on: KeyboardService.scrollLock, label: "Scroll", short: "S" }
    ].filter(k => k.show && (k.on || !root.options.hideWhenOff))

    Component.onCompleted: KeyboardService.lockKeyWatchers++
    Component.onDestruction: KeyboardService.lockKeyWatchers--

    shown: keys.length > 0
    implicitWidth: shown ? grid.implicitWidth : 0
    implicitHeight: shown ? grid.implicitHeight : 0

    LineLayout {
        id: grid
        anchors.centerIn: parent
        vertical: root.vertical
        spacing: Math.round(root.fontSize * 0.5)

        Repeater {
            model: root.keys

            VText {
                required property var modelData
                Layout.alignment: Qt.AlignCenter
                text: root.vertical ? modelData.short : modelData.label
                color: modelData.on ? Theme.accent : Theme.textMuted
                font.weight: modelData.on ? Font.Bold : Style.fontWeight
                font.pixelSize: root.fontSize * (root.vertical ? 0.85 : 0.9)
            }
        }
    }
}
