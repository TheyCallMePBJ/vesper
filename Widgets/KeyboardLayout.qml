import QtQuick
import qs.Commons
import qs.Components
import qs.Services

// Active keyboard layout. Left click switches to the next layout.
BarWidget {
    id: root

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    BarPill {
        id: pill
        anchors.centerIn: parent
        vertical: root.vertical
        barThickness: root.barThickness
        fontSize: root.fontSize
        icon: root.options.showIcon ? "keyboard" : ""
        text: root.options.display === "name" && !root.vertical ? KeyboardService.layoutName : KeyboardService.layoutCode.toUpperCase()
        interactive: KeyboardService.layoutCount > 1

        onClicked: KeyboardService.nextLayout()
    }
}
