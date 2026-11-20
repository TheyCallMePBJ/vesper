import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Components
import qs.Services

ColumnLayout {
    id: root

    spacing: Math.round(Style.fontSize * 1.6)

    readonly property var sectionIds: ["left", "center", "right"]
    readonly property bool vertical: Settings.bar.position === "left" || Settings.bar.position === "right"
    readonly property var widgets: Settings.bar.widgets || ({})

    // Which entry has its options open, as "section:index".
    property string expandedKey: ""

    function sectionLabel(id) {
        return vertical ? ({ left: "Top", center: "Middle", right: "Bottom" })[id]
                        : ({ left: "Left", center: "Center", right: "Right" })[id];
    }

    function entries(section) {
        return widgets[section] || [];
    }

    // Copy the widget lists, let fn change them, then save.
    function edit(fn) {
        const next = JSON.parse(JSON.stringify(widgets));
        for (const id of sectionIds)
            if (!Array.isArray(next[id]))
                next[id] = [];
        fn(next);
        Settings.set("bar.widgets", next);
    }

    function isUsed(type) {
        return sectionIds.some(id => entries(id).some(e => e.type === type));
    }

    function addOptions() {
        return WidgetRegistry.types
            .filter(t => WidgetRegistry.get(t).allowMultiple || !isUsed(t))
            .map(t => ({ value: t, label: WidgetRegistry.get(t).name }));
    }

    function add(section, type) {
        edit(w => w[section].push({ type: type }));
        expandedKey = "";
    }

    function remove(section, index) {
        edit(w => w[section].splice(index, 1));
        expandedKey = "";
    }

    // Moving past the start/end of a section moves into the neighbouring one.
    function move(section, index, dir) {
        const si = sectionIds.indexOf(section);
        const list = entries(section);
        let target = section;
        let targetIndex = index + dir;
        if (targetIndex < 0) {
            if (si === 0)
                return;
            target = sectionIds[si - 1];
            targetIndex = entries(target).length;
        } else if (targetIndex >= list.length) {
            if (si === sectionIds.length - 1)
                return;
            target = sectionIds[si + 1];
            targetIndex = 0;
        }
        const wasExpanded = expandedKey === `${section}:${index}`;
        edit(w => {
            const [entry] = w[section].splice(index, 1);
            w[target].splice(targetIndex, 0, entry);
        });
        expandedKey = wasExpanded ? `${target}:${targetIndex}` : "";
    }

    function setOption(section, index, key, value) {
        edit(w => {
            const entry = Object.assign({}, w[section][index]);
            entry[key] = value;
            w[section][index] = WidgetRegistry.compactEntry(entry);
        });
    }

    VText {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        color: Theme.textMuted
        text: "Add, remove and arrange the widgets on your bar. The arrows move a widget along the bar, and into the next section when it reaches the end of one."
    }

    Repeater {
        model: root.sectionIds

        SettingsSection {
            id: section
            required property string modelData
            readonly property var list: root.entries(modelData)

            title: root.sectionLabel(modelData)

            VText {
                visible: section.list.length === 0
                text: "No widgets"
                color: Theme.textMuted
            }

            Repeater {
                model: section.list

                WidgetEntry {
                    required property var modelData
                    required property int index

                    entry: modelData
                    vertical: root.vertical
                    expanded: root.expandedKey === `${section.modelData}:${index}`
                    canMoveUp: !(section.modelData === root.sectionIds[0] && index === 0)
                    canMoveDown: !(section.modelData === root.sectionIds[root.sectionIds.length - 1] && index === section.list.length - 1)

                    onMoveUp: root.move(section.modelData, index, -1)
                    onMoveDown: root.move(section.modelData, index, 1)
                    onRemoveRequested: root.remove(section.modelData, index)
                    onToggleExpanded: root.expandedKey = expanded ? "" : `${section.modelData}:${index}`
                    onOptionChanged: (key, value) => root.setOption(section.modelData, index, key, value)
                }
            }

            VComboBox {
                Layout.alignment: Qt.AlignLeft
                placeholder: "Add widget…"
                options: root.addOptions()
                enabled: options.length > 0
                onChangedByUser: type => root.add(section.modelData, type)
            }
        }
    }
}
