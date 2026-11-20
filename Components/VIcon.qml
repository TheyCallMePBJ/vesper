import QtQuick
import qs.Commons

// A Tabler icon by name: VIcon { icon: "volume"; size: 16 }
Text {
    property string icon: ""
    property real size: Style.fontSize * 1.25

    text: Icons.glyph(icon)
    color: Theme.text
    font.family: Icons.fontFamily
    font.pixelSize: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
