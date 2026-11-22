pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.Commons

// What's using the microphone, camera or screen, as seen in PipeWire:
// - microphone: apps recording audio (ignoring privacy.ignoredApps)
// - camera: anything linked to a camera (only apps that use the camera
//   through PipeWire; apps opening /dev/video directly aren't seen)
// - screen: screen sharing through xdg-desktop-portal-hyprland
Singleton {
    id: root

    function ignored(name) {
        const n = String(name || "").toLowerCase();
        return (Settings.privacy.ignoredApps || []).some(a => a && n.includes(String(a).toLowerCase()));
    }

    readonly property var nodes: Pipewire.nodes.values
    readonly property var links: Pipewire.linkGroups.values

    readonly property var micApps: unique(nodes.filter(n => n.isStream && n.type === PwNodeType.AudioInStream && !ignored(n.name)).map(n => n.name))

    readonly property var cameraApps: unique(links.filter(g => g.source && g.target && g.source.type === PwNodeType.VideoSource && !isScreen(g.source))
                                                  .map(g => g.target.name))

    readonly property var screenApps: {
        const screens = nodes.filter(n => isScreen(n));
        const users = links.filter(g => g.source && g.target && isScreen(g.source)).map(g => g.target.name);
        return screens.length === 0 ? [] : users.length > 0 ? unique(users) : ["Screen sharing"];
    }

    readonly property bool micInUse: micApps.length > 0
    readonly property bool cameraInUse: cameraApps.length > 0
    readonly property bool screenShared: screenApps.length > 0
    readonly property bool anyInUse: micInUse || cameraInUse || screenShared

    function isScreen(node) {
        return /^xdph/.test(node.name || "");
    }

    function unique(list) {
        return list.filter((v, i) => v && list.indexOf(v) === i);
    }
}
