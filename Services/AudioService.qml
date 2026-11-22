pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.Commons

// Default speaker (sink) and microphone (source) through PipeWire.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool sinkReady: !!(sink && sink.audio)
    readonly property bool sourceReady: !!(source && source.audio)

    readonly property real volume: sinkReady ? sink.audio.volume : 0
    readonly property bool muted: sinkReady ? sink.audio.muted : true
    readonly property real micVolume: sourceReady ? source.audio.volume : 0
    readonly property bool micMuted: sourceReady ? source.audio.muted : true

    // Every output and input device, and the apps playing audio.
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && !n.isStream && n.isSink)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isStream && !n.isSink)
    readonly property var playbackStreams: Pipewire.nodes.values.filter(n => n.audio && n.isStream && n.type === PwNodeType.AudioOutStream)

    readonly property real step: Math.max(1, Settings.audio.volumeStep || 5) / 100

    // Volume and mute are only available for nodes that are tracked.
    PwObjectTracker {
        objects: [root.sink, root.source].filter(n => n)
    }

    function clamp(v) {
        return Math.max(0, Math.min(1, v));
    }

    function setVolume(v) {
        if (!sinkReady)
            return;
        sink.audio.volume = clamp(v);
        if (sink.audio.muted && v > 0)
            sink.audio.muted = false;
    }
    function changeVolume(direction) {
        setVolume(Math.round((volume + direction * step) * 100) / 100);
    }
    function toggleMute() {
        if (sinkReady)
            sink.audio.muted = !sink.audio.muted;
    }

    function setMicVolume(v) {
        if (sourceReady)
            source.audio.volume = clamp(v);
    }
    function changeMicVolume(direction) {
        setMicVolume(Math.round((micVolume + direction * step) * 100) / 100);
    }
    function toggleMicMute() {
        if (sourceReady)
            source.audio.muted = !source.audio.muted;
    }

    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }
    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }

    // Display name of a device or app stream.
    function nodeName(node) {
        if (!node)
            return "";
        const p = node.properties || {};
        if (node.isStream)
            return p["application.name"] || node.description || node.name;
        return node.description || node.nickname || node.name;
    }

    function volumeIcon(v, isMuted) {
        if (isMuted || v <= 0.005)
            return "volume-off";
        return v < 0.5 ? "volume-2" : "volume";
    }
}
