pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The media player widgets should show: one that's playing, else the one that
// played most recently, else the first one that can be controlled.
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property MprisPlayer lastPlaying: null

    readonly property MprisPlayer player: {
        const list = players.filter(p => p && p.canControl);
        const playing = list.find(p => p.isPlaying);
        if (playing)
            return playing;
        if (lastPlaying && list.includes(lastPlaying))
            return lastPlaying;
        return list.length > 0 ? list[0] : null;
    }

    readonly property bool hasPlayer: player !== null
    readonly property bool isPlaying: hasPlayer && player.isPlaying
    readonly property string title: hasPlayer ? (player.trackTitle || player.identity || "") : ""
    readonly property string artist: hasPlayer ? (player.trackArtist || "") : ""

    onPlayerChanged: if (player && player.isPlaying) lastPlaying = player

    Connections {
        target: root.player
        function onIsPlayingChanged() {
            if (root.player && root.player.isPlaying)
                root.lastPlaying = root.player;
        }
    }

    function togglePlaying() {
        if (hasPlayer && player.canTogglePlaying)
            player.togglePlaying();
    }
    function next() {
        if (hasPlayer && player.canGoNext)
            player.next();
    }
    function previous() {
        if (hasPlayer && player.canGoPrevious)
            player.previous();
    }
}
