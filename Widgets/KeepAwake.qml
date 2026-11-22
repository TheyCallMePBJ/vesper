import QtQuick
import qs.Commons
import qs.Components
import qs.Services

// Click to stop the screen from going idle (blank / lock) until clicked again.
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
        icon: KeepAwakeService.enabled ? "coffee" : "coffee-off"
        iconColor: KeepAwakeService.enabled ? Theme.accent : Theme.textMuted
        onClicked: KeepAwakeService.toggle()
    }
}
