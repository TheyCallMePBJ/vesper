import QtQuick
import qs.Commons
import qs.Components
import qs.Services

// Bell with the number of unread notifications. Click: history. Right click:
// do not disturb on/off.
BarWidget {
    id: root

    readonly property int unread: NotificationService.unread
    readonly property bool dnd: NotificationService.doNotDisturb

    panelName: "notifications"
    shown: !(options.hideWhenEmpty && NotificationService.history.length === 0 && !dnd)
    implicitWidth: shown ? pill.implicitWidth : 0
    implicitHeight: shown ? pill.implicitHeight : 0

    BarPill {
        id: pill
        anchors.centerIn: parent
        vertical: root.vertical
        barThickness: root.barThickness
        fontSize: root.fontSize
        icon: root.dnd ? "bell-off" : (root.unread > 0 ? "bell-ringing" : "bell")
        iconColor: root.dnd ? Theme.textMuted : (root.unread > 0 ? Theme.accent : Theme.text)
        text: root.options.showCount && root.unread > 0 ? String(root.unread) : ""
        textColor: Theme.accent
        active: root.panelOpen
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                NotificationService.setDoNotDisturb(!root.dnd);
            else
                root.togglePanel();
        }
    }
}
