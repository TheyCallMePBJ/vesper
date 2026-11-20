import QtQuick
import Quickshell
import Quickshell.Io

// Runs `command` with sh -c every `interval` seconds and keeps the first line
// of its output in `output`. Does nothing while `command` is empty.
Item {
    id: root

    property string command: ""
    property int interval: 10
    property string output: ""

    function runNow() {
        if (command === "" || proc.running)
            return;
        // Set explicitly: a binding may not have updated yet when this runs
        // from onCommandChanged.
        proc.command = ["sh", "-c", command];
        proc.running = true;
    }

    onCommandChanged: {
        output = "";
        runNow();
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: root.output = text.split("\n")[0].trim()
        }
    }

    Timer {
        interval: Math.max(1, root.interval) * 1000
        repeat: true
        running: root.command !== ""
        triggeredOnStart: true
        onTriggered: root.runNow()
    }
}
