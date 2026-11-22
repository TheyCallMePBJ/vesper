pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// Runs the configurable bar actions (scroll / right-click / middle-click on
// empty bar space). Actions whose feature isn't built yet just log.
Singleton {
    id: root

    // Wheel deltas arrive in small steps on touchpads; act once per notch
    // (120 units), or in "swipe" mode once per gesture.
    property real wheelAccumulator: 0
    // In swipe mode: a step was taken and the gesture hasn't ended yet.
    property bool swipeUsed: false

    // A gesture ends after this long without scroll events.
    Timer {
        id: swipeEnd
        interval: 250
        onTriggered: {
            root.swipeUsed = false;
            root.wheelAccumulator = 0;
        }
    }

    function handleWheel(barConfig, angleDelta, screen) {
        const actions = barConfig.actions;
        if (actions.scroll === "none")
            return;

        if (actions.scrollMode === "swipe") {
            swipeEnd.restart();
            if (swipeUsed)
                return;
            wheelAccumulator += angleDelta;
            // A wheel notch is 120; touchpads need a short deliberate swipe.
            if (Math.abs(wheelAccumulator) < 60)
                return;
            swipeUsed = true;
        } else {
            wheelAccumulator += angleDelta;
            if (Math.abs(wheelAccumulator) < 120)
                return;
        }

        let up = wheelAccumulator > 0;
        wheelAccumulator = 0;
        if (actions.reverseScroll)
            up = !up;

        switch (actions.scroll) {
        case "none":
            return;
        case "workspace":
            HyprlandService.stepWorkspace(screen ? screen.name : "", up ? -1 : 1);
            return;
        case "volume":
            AudioService.changeVolume(up ? 1 : -1);
            return;
        default:
            Logger.w("BarActions", `Unknown scroll action "${actions.scroll}".`);
        }
    }

    // Choices shown in the settings window. Only actions that work are listed;
    // more are added as their features are built.
    readonly property var scrollActions: [
        { value: "none", label: "Nothing" },
        { value: "workspace", label: "Switch workspace" },
        { value: "volume", label: "Change volume" }
    ]
    readonly property var clickActions: [
        { value: "none", label: "Nothing" },
        { value: "settings", label: "Open settings" },
        { value: "sessionMenu", label: "Open session menu" },
        { value: "controlCenter", label: "Open control center" },
        { value: "command", label: "Run a command" }
    ]

    function handleClick(clickConfig, screen) {
        if (!clickConfig || !clickConfig.action)
            return;
        switch (clickConfig.action) {
        case "none":
            return;
        case "command":
            if (clickConfig.command)
                Quickshell.execDetached(["sh", "-c", clickConfig.command]);
            return;
        case "settings":
            Panels.toggleSettings(screen);
            return;
        case "sessionMenu":
            Panels.toggleSession(screen);
            return;
        case "controlCenter":
            Panels.togglePanel("controlCenter", null, screen);
            return;
        case "launcher":
            Logger.d("BarActions", `Click action "${clickConfig.action}" isn't available yet.`);
            return;
        default:
            Logger.w("BarActions", `Unknown click action "${clickConfig.action}".`);
        }
    }
}
