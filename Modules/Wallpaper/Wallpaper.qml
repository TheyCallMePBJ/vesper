import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services

// The wallpaper on one screen, on the background layer. Changing it fades the
// new image in over the old one.
PanelWindow {
    id: root

    required property ShellScreen modelData
    screen: modelData
    // Nothing chosen for this screen: leave whatever is underneath.
    visible: path !== ""

    readonly property string path: WallpaperService.pathFor(modelData.name)
    readonly property int fill: ({
        crop: Image.PreserveAspectCrop,
        fit: Image.PreserveAspectFit,
        stretch: Image.Stretch,
        center: Image.Pad,
        tile: Image.Tile
    })[Settings.wallpaper.fillMode] ?? Image.PreserveAspectCrop

    WlrLayershell.namespace: "vesper-wallpaper"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "black"

    // Two images take turns: the new one loads in `front` and fades in over
    // `back`, which then takes its place.
    property Image front: a
    property Image back: b

    function show(path) {
        const next = back;
        next.opacity = 0;
        next.z = 1;
        front.z = 0;
        next.source = WallpaperService.fileUrl(path);
        back = front;
        front = next;
    }

    onPathChanged: show(path)
    Component.onCompleted: {
        a.source = WallpaperService.fileUrl(path);
        a.opacity = 1;
    }

    component Layer: Image {
        id: layer
        anchors.fill: parent
        fillMode: root.fill
        // Decode at screen size, not the file's size.
        // (0 = the file's own size, for tiling and centring.)
        sourceSize.width: root.fill === Image.Tile || root.fill === Image.Pad ? 0 : root.width
        sourceSize.height: root.fill === Image.Tile || root.fill === Image.Pad ? 0 : root.height
        asynchronous: true
        cache: false
        smooth: true
        opacity: 0

        onStatusChanged: {
            if (layer === root.front && (status === Image.Ready || status === Image.Error)) {
                if (status === Image.Error)
                    Logger.w("Wallpaper", `Couldn't load ${source}`);
                fade.target = layer;
                fade.restart();
            }
        }
    }

    Layer { id: a }
    Layer { id: b }

    NumberAnimation {
        id: fade
        property: "opacity"
        to: 1
        duration: Math.max(0, Settings.wallpaper.transition || 0)
        easing.type: Easing.InOutQuad
        // Free the old image once the new one covers it.
        onFinished: if (root.back.source !== "" && root.front.status === Image.Ready) root.back.source = ""
    }
}
