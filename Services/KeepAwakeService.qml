pragma Singleton

import QtQuick
import Quickshell

// Keeps the screen from blanking or locking for idle. The bars hold the
// actual idle inhibitors (they need a window). Not saved: resets on restart.
Singleton {
    property bool enabled: false

    function toggle() {
        enabled = !enabled;
    }
}
