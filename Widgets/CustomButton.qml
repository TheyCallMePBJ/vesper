import QtQuick
import Quickshell
import qs.Commons
import qs.Components

// Icon + label that runs commands on click. The label can come from a command.
BarWidget {
    id: root

    readonly property bool hasClick: !!(options.leftClick || options.rightClick || options.middleClick)

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    CommandRunner {
        id: runner
        command: root.options.labelCommand || ""
        interval: root.options.labelInterval
    }

    function run(cmd) {
        if (cmd)
            Quickshell.execDetached(["sh", "-c", cmd]);
    }

    BarPill {
        id: pill
        anchors.centerIn: parent
        vertical: root.vertical
        barThickness: root.barThickness
        fontSize: root.fontSize
        icon: root.options.icon || ""
        text: root.options.labelCommand ? runner.output : (root.options.label || "")
        textOnVertical: false
        maxTextWidth: root.fontSize * 20
        interactive: root.hasClick
        acceptedButtons: (root.options.leftClick ? Qt.LeftButton : 0)
                       | (root.options.rightClick ? Qt.RightButton : 0)
                       | (root.options.middleClick ? Qt.MiddleButton : 0)

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.run(root.options.rightClick);
            else if (mouse.button === Qt.MiddleButton)
                root.run(root.options.middleClick);
            else
                root.run(root.options.leftClick);
            // Refresh a command-driven label right away (e.g. after toggling something).
            runner.runNow();
        }
    }
}
