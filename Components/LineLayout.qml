import QtQuick
import QtQuick.Layouts

// Lays children out in one row, or one column when `vertical`. Unlike Grid,
// hidden children take no space and there's no gap after the last child, so
// centred content stays centred. Give children `Layout.alignment: Qt.AlignCenter`
// so they're centred across the line too.
GridLayout {
    property bool vertical: false
    property real spacing: 0

    flow: vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
    // Only the limit along the flow matters; the other is effectively unlimited.
    rows: vertical ? 10000 : 1
    columns: vertical ? 1 : 10000
    rowSpacing: spacing
    columnSpacing: spacing
}
