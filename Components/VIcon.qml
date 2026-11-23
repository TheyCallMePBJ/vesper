import QtQuick
import qs.Commons

// A Tabler icon by name: VIcon { icon: "volume"; size: 16 }
//
// Partial Wi-Fi levels (wifi-0, wifi-1, wifi-2) are drawn over the full Wi-Fi
// shape in a dim colour, so the icon keeps the same outline at every signal
// strength instead of shrinking to its bottom arcs.
Text {
    id: root

    property string icon: ""
    property real size: Style.fontSize * 1.25

    readonly property bool partialWifi: /^wifi-[0-2]$/.test(icon)

    text: Icons.glyph(icon)
    color: Theme.text
    font.family: Icons.fontFamily
    font.pixelSize: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    Text {
        visible: root.partialWifi
        anchors.fill: parent
        z: -1
        text: Icons.glyph("wifi")
        color: Qt.alpha(root.color, 0.3)
        font: root.font
        horizontalAlignment: root.horizontalAlignment
        verticalAlignment: root.verticalAlignment
    }
}
