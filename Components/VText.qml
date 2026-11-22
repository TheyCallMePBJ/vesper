import QtQuick
import qs.Commons

// Text with the theme's colour and font applied.
Text {
    color: Theme.text
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize
    font.weight: Style.fontWeight
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
}
