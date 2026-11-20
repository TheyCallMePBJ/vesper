import QtQuick
import QtQuick.Controls.Basic as T
import qs.Commons

// Dropdown. `options` is a list of { value, label }. Bind `value`; handle
// `changedByUser(value)`. Leave `value` unset and set `placeholder` to use it
// as an "Add ..." menu.
T.ComboBox {
    id: root

    property var options: []
    property var value: undefined
    property string placeholder: ""

    signal changedByUser(var value)

    function indexFor(v) {
        for (let i = 0; i < options.length; i++)
            if (options[i].value === v)
                return i;
        return -1;
    }

    model: options
    textRole: "label"
    valueRole: "value"
    currentIndex: indexFor(value)
    displayText: currentIndex >= 0 ? options[currentIndex].label : placeholder
    hoverEnabled: true
    implicitHeight: Math.round(Style.fontSize * 2.4)
    implicitWidth: Math.round(Style.fontSize * 14)
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize
    opacity: enabled ? 1 : 0.4

    onActivated: index => {
        changedByUser(options[index].value);
        currentIndex = Qt.binding(() => root.indexFor(root.value));
    }

    contentItem: VText {
        leftPadding: Math.round(Style.fontSize * 0.8)
        rightPadding: root.indicator.width + Style.fontSize * 0.4
        text: root.displayText
        color: root.currentIndex >= 0 ? Theme.text : Theme.textMuted
        elide: Text.ElideRight
    }

    indicator: VIcon {
        x: root.width - width - Math.round(Style.fontSize * 0.6)
        y: (root.height - height) / 2
        icon: "selector"
        color: Theme.textMuted
        size: Style.fontSize * 1.1
    }

    background: Rectangle {
        radius: Style.radius
        color: root.hovered ? Qt.lighter(Theme.surface, 1.12) : Theme.surface
        border.width: 1
        border.color: root.popup.visible ? Theme.accent : Theme.border
    }

    delegate: T.ItemDelegate {
        id: item
        required property var modelData
        required property int index
        width: ListView.view ? ListView.view.width : implicitWidth
        height: Math.round(Style.fontSize * 2.2)
        hoverEnabled: true
        highlighted: root.highlightedIndex === index

        contentItem: VText {
            text: item.modelData.label
            color: item.index === root.currentIndex ? Theme.accent : Theme.text
            font.bold: item.index === root.currentIndex
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: Style.radius - 2
            color: item.highlighted || item.hovered ? Theme.surfaceAlt : "transparent"
        }
    }

    popup: T.Popup {
        y: root.height + 4
        width: root.width
        implicitHeight: Math.min(contentItem.implicitHeight + topPadding + bottomPadding, Style.fontSize * 24)
        padding: 4

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            boundsBehavior: Flickable.StopAtBounds
            T.ScrollBar.vertical: T.ScrollBar {}
        }

        background: Rectangle {
            radius: Style.radius
            color: Theme.background
            border.width: 1
            border.color: Theme.border
        }
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
