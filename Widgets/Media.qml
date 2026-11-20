import QtQuick
import qs.Commons
import qs.Components
import qs.Services

// Left click: play/pause. Right click: next track. Middle click: previous.
BarWidget {
    id: root

    readonly property string label: {
        if (!MediaService.hasPlayer)
            return "";
        if (root.options.showArtist && MediaService.artist !== "")
            return `${MediaService.artist} – ${MediaService.title}`;
        return MediaService.title;
    }

    shown: MediaService.hasPlayer && !(root.options.hideWhenPaused && !MediaService.isPlaying)
    implicitWidth: shown ? pill.implicitWidth : 0
    implicitHeight: shown ? pill.implicitHeight : 0

    BarPill {
        id: pill
        anchors.centerIn: parent
        vertical: root.vertical
        barThickness: root.barThickness
        fontSize: root.fontSize
        icon: MediaService.isPlaying ? "player-pause" : "player-play"
        iconColor: MediaService.isPlaying ? Theme.accent : Theme.text
        text: root.label
        textColor: MediaService.isPlaying ? Theme.text : Theme.textMuted
        maxTextWidth: root.options.maxWidth
        textOnVertical: false
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                MediaService.next();
            else if (mouse.button === Qt.MiddleButton)
                MediaService.previous();
            else
                MediaService.togglePlaying();
        }
    }
}
