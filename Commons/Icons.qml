pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Bundled Tabler icons (outline set, Assets/fonts). Use through VIcon:
//   VIcon { icon: "settings" }
// Names are the ones on https://tabler.io/icons without the "ti-" prefix.
Singleton {
    id: root

    readonly property string fontFamily: fontLoader.status === FontLoader.Ready ? fontLoader.name : ""
    property var codepoints: ({})
    property var warned: ({})

    function glyph(name) {
        if (!name)
            return "";
        const cp = codepoints[name];
        if (cp === undefined) {
            // The map may still be loading on the very first call.
            if (Object.keys(codepoints).length > 0 && !warned[name]) {
                warned[name] = true;
                Logger.w("Icons", `Unknown icon "${name}"`);
            }
            return "";
        }
        return String.fromCodePoint(cp);
    }

    function exists(name) {
        return codepoints[name] !== undefined;
    }

    FontLoader {
        id: fontLoader
        source: Qt.resolvedUrl("../Assets/fonts/tabler-icons.ttf")
        onStatusChanged: if (status === FontLoader.Error) Logger.e("Icons", "Could not load the icon font")
    }

    FileView {
        path: Quickshell.shellDir + "/Assets/fonts/tabler-icons.json"
        blockLoading: true
        onLoaded: {
            try {
                root.codepoints = JSON.parse(text());
            } catch (err) {
                Logger.e("Icons", `Could not parse the icon map: ${err.message}`);
            }
        }
    }
}
