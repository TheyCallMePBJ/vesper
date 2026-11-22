import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Components
import qs.Services

// One notification: image or app icon, app name and time, summary, body and
// action buttons. Clicking the body runs the app's default action.
Rectangle {
    id: root

    required property NotificationEntry entry
    // Popups are shorter (the body is cut after a few lines) and have a border.
    property bool popup: false
    // Current time, for "5m ago". Bound by the parent so one clock serves all cards.
    property real now: Date.now()
    readonly property bool hovered: hover.hovered

    readonly property real pad: Math.round(Style.fontSize * 0.9)
    readonly property real imageSize: Math.round(Style.fontSize * 3)

    implicitHeight: layout.implicitHeight + pad * 2
    radius: Style.radius * 1.5
    color: popup ? Theme.background : Qt.alpha(Theme.surface, hover.hovered ? 0.8 : 0.5)
    border.width: popup ? 1 : 0
    border.color: entry.critical ? Theme.error : Theme.border

    HoverHandler { id: hover }

    // Body click: default action.
    MouseArea {
        anchors.fill: parent
        enabled: root.entry.live && root.entry.actions.some(a => a.identifier === "default")
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: NotificationService.activate(root.entry)
    }

    // Critical: a coloured strip on the left.
    Rectangle {
        visible: root.entry.critical
        width: 3
        radius: 1.5
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: root.pad * 0.6
        color: Theme.error
    }

    RowLayout {
        id: layout
        x: root.pad
        y: root.pad
        width: parent.width - root.pad * 2
        spacing: root.pad

        // Picture: the notification's image, else the app's icon, else a bell.
        Item {
            id: picture
            Layout.alignment: Qt.AlignTop
            implicitWidth: root.imageSize
            implicitHeight: root.imageSize

            // Image and icon can be file paths, image:// URLs or icon names
            // (which might not be installed, so look them up first).
            readonly property string imageSource: root.resolve(root.entry.image)
            readonly property string appIconSource: {
                const e = root.entry;
                return root.resolve(e.appIcon) || AppIcons.firstFound([e.desktopEntry, e.appName]);
            }

            ClippingRectangle {
                anchors.fill: parent
                radius: Style.radius
                color: "transparent"
                visible: picture.imageSource !== ""

                Image {
                    anchors.fill: parent
                    source: picture.imageSource
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: root.imageSize * 2
                    sourceSize.height: root.imageSize * 2
                    asynchronous: true
                    cache: false
                }
            }

            IconImage {
                anchors.centerIn: parent
                visible: picture.imageSource === "" && picture.appIconSource !== ""
                implicitSize: Math.round(root.imageSize * 0.8)
                source: picture.appIconSource
                asynchronous: true
            }

            Rectangle {
                anchors.fill: parent
                visible: picture.imageSource === "" && picture.appIconSource === ""
                radius: Style.radius
                color: Theme.surfaceAlt

                VIcon {
                    anchors.centerIn: parent
                    icon: root.entry.critical ? "alert-triangle" : "bell"
                    color: root.entry.critical ? Theme.error : Theme.textMuted
                    size: root.imageSize * 0.5
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: Math.round(Style.fontSize * 0.2)

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(Style.fontSize * 0.4)

                VText {
                    Layout.fillWidth: true
                    text: {
                        const app = root.entry.appName || "Notification";
                        const when = root.timeAgo(root.entry.time, root.now);
                        return when ? `${app} · ${when}` : app;
                    }
                    elide: Text.ElideRight
                    color: Theme.textMuted
                    font.pixelSize: Style.fontSize * 0.85
                }

                // Space for the close button, which floats over the corner.
                Item {
                    implicitWidth: closeButton.size * 0.7
                    implicitHeight: 1
                }
            }

            VText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.entry.summary
                font.bold: true
                wrapMode: Text.Wrap
                maximumLineCount: root.popup ? 2 : 4
                elide: Text.ElideRight
            }

            VText {
                Layout.fillWidth: true
                visible: root.entry.body !== ""
                text: root.styledBody(root.entry.body)
                textFormat: Text.StyledText
                color: Theme.textMuted
                linkColor: Theme.accent
                wrapMode: Text.Wrap
                maximumLineCount: root.popup ? 4 : 8
                elide: Text.ElideRight
                onLinkActivated: link => Qt.openUrlExternally(link)

                HoverHandler {
                    enabled: parent.hoveredLink !== ""
                    cursorShape: Qt.PointingHandCursor
                }
            }

            // App actions (only while the app still has the notification open).
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: Math.round(Style.fontSize * 0.3)
                visible: buttons.count > 0
                spacing: Math.round(Style.fontSize * 0.4)

                Repeater {
                    id: buttons
                    model: root.entry.live ? root.entry.actions.filter(a => a.identifier !== "default" && a.text !== "") : []

                    VButton {
                        required property var modelData
                        text: modelData.text
                        onClicked: NotificationService.invokeAction(root.entry, modelData.identifier)
                    }
                }
            }
        }
    }

    VIconButton {
        id: closeButton
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Math.round(root.pad * 0.4)
        size: Math.round(Style.fontSize * 1.8)
        iconName: "x"
        iconColor: Theme.textMuted
        tooltip: root.popup ? "Dismiss" : "Remove"
        opacity: hover.hovered || root.popup ? 1 : 0
        onClicked: NotificationService.dismiss(root.entry)
    }

    function resolve(source) {
        if (!source)
            return "";
        if (source.startsWith("/"))
            return "file://" + source;
        if (source.startsWith("image://icon/"))
            return AppIcons.forApp(source.slice(13).split("?")[0]);
        if (/^[a-z]+:\/\//.test(source))
            return source;
        return AppIcons.forApp(source);
    }

    // Notification bodies use a small HTML subset. Images are dropped (they
    // could load remote content); plain newlines become line breaks.
    function styledBody(text) {
        return text.replace(/<img[^>]*>/gi, "").replace(/\r?\n/g, "<br>");
    }

    function timeAgo(time, now) {
        const seconds = Math.max(0, (now - time) / 1000);
        if (root.popup || seconds < 60)
            return root.popup ? "" : "now";
        if (seconds < 3600)
            return `${Math.floor(seconds / 60)}m ago`;
        if (seconds < 86400)
            return `${Math.floor(seconds / 3600)}h ago`;
        const d = new Date(time);
        const days = Math.floor(seconds / 86400);
        return days === 1 ? "yesterday" : days < 7 ? Qt.formatDate(d, "dddd") : Qt.formatDate(d, "d MMM");
    }
}
