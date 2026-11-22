import QtQuick
import qs.Commons
import qs.Components
import qs.Services

// Night light switch. Highlighted while the screen is warmed; dimmed while
// it's on but outside its schedule. Hidden if hyprsunset isn't installed.
BarWidget {
    id: root

    shown: NightLightService.installed
    implicitWidth: shown ? pill.implicitWidth : 0
    implicitHeight: shown ? pill.implicitHeight : 0

    BarPill {
        id: pill
        anchors.centerIn: parent
        vertical: root.vertical
        barThickness: root.barThickness
        fontSize: root.fontSize
        icon: NightLightService.enabled ? "moon-stars" : "moon"
        iconColor: NightLightService.active ? Theme.warning : NightLightService.enabled ? Theme.text : Theme.textMuted
        onClicked: NightLightService.toggle()
    }
}
