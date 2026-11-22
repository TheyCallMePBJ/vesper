import QtQuick
import QtQuick.Layouts
import qs.Commons

// The standard look for a bar widget: an icon and/or text with a hover
// background. Lays out in a row on horizontal bars and a column on vertical
// ones. Only the mouse buttons in `acceptedButtons` are taken; other clicks
// and (unless `handlesWheel`) scrolling fall through to the bar's actions.
MouseArea {
    id: root

    property string icon: ""
    property string text: ""
    property color iconColor: Theme.text
    property color textColor: Theme.text
    property bool vertical: false
    property real barThickness: 30
    property real fontSize: 13
    // Max width of the text on a horizontal bar; longer text is elided.
    property real maxTextWidth: 0
    // On a vertical bar, show the text under the icon (keep it short).
    property bool textOnVertical: true
    property bool handlesWheel: false
    property bool interactive: true
    // Keeps the hover background on, e.g. while the widget's panel is open.
    property bool active: false

    // One step per wheel notch: +1 = up/away, -1 = down/towards.
    signal wheelStep(int direction)
    property real wheelAccumulator: 0

    readonly property bool showIcon: icon !== ""
    readonly property bool showText: text !== "" && (!vertical || textOnVertical)
    // How far the hover background reaches past the content along the bar.
    // It's drawn outside the widget's size, so the bar lays widgets out by
    // their visible content: edge padding and widget spacing are measured to
    // the icon/text itself.
    readonly property real pad: Math.round(fontSize * 0.35)
    readonly property real cell: Math.round(barThickness * 0.8)

    implicitWidth: vertical ? cell : content.implicitWidth
    implicitHeight: vertical ? content.implicitHeight : cell

    hoverEnabled: interactive
    cursorShape: interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    acceptedButtons: interactive ? Qt.LeftButton : Qt.NoButton

    onWheel: wheel => {
        if (!handlesWheel) {
            wheel.accepted = false;
            return;
        }
        wheelAccumulator += wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
        while (Math.abs(wheelAccumulator) >= 120) {
            const dir = wheelAccumulator > 0 ? 1 : -1;
            wheelAccumulator -= dir * 120;
            wheelStep(dir);
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: root.vertical ? 0 : -root.pad
        anchors.rightMargin: root.vertical ? 0 : -root.pad
        anchors.topMargin: root.vertical ? -root.pad : 0
        anchors.bottomMargin: root.vertical ? -root.pad : 0
        radius: Style.radius
        color: root.pressed ? Theme.surfaceAlt : Theme.surface
        opacity: root.active || (root.interactive && (root.containsMouse || root.pressed)) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Style.animationDuration } }
    }

    LineLayout {
        id: content
        anchors.centerIn: parent
        vertical: root.vertical
        spacing: Math.round(root.fontSize * (root.vertical ? 0.1 : 0.35))

        VIcon {
            Layout.alignment: Qt.AlignCenter
            visible: root.showIcon
            icon: root.icon
            color: root.iconColor
            size: Style.barIconSize(root.fontSize)
        }

        VText {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: !root.vertical && root.maxTextWidth > 0 ? Math.min(implicitWidth, root.maxTextWidth) : implicitWidth
            visible: root.showText
            text: root.text
            color: root.textColor
            font.pixelSize: root.vertical ? root.fontSize * 0.8 : root.fontSize
            elide: Text.ElideRight
        }
    }
}
