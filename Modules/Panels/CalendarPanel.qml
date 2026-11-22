import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Components
import qs.Services

// Month calendar, opened from the clock. Scroll or use the arrows to change
// month; click the month name to go back to today.
BarPanel {
    id: root

    defaultAlign: "center"
    panelWidth: Math.round(Style.fontSize * (Settings.calendar.showWeekNumbers ? 23 : 21))

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property date today: clock.date
    // 12 or 24 hour, like the bar's Clock widget (else the locale).
    readonly property bool use24h: {
        const w = Settings.bar.widgets || {};
        const clockEntry = [].concat(w.left || [], w.center || [], w.right || []).find(e => e.type === "Clock");
        const format = (clockEntry && clockEntry.format) || (clockEntry ? "HH:mm" : Qt.locale().timeFormat(Locale.ShortFormat));
        return !/[hH]/.test(format) || /H/.test(format.replace(/'[^']*'/g, ""));
    }
    // First day of the month being shown.
    property int shownYear: today.getFullYear()
    property int shownMonth: today.getMonth()

    readonly property int firstDay: {
        const setting = Settings.calendar.firstDayOfWeek;
        return setting >= 0 && setting <= 6 ? setting : Qt.locale().firstDayOfWeek % 7;
    }

    // 42 days (6 weeks) starting on the first `firstDay` on or before the 1st.
    readonly property var days: {
        const first = new Date(shownYear, shownMonth, 1);
        const offset = (first.getDay() - firstDay + 7) % 7;
        const out = [];
        for (let i = 0; i < 42; i++)
            out.push(new Date(shownYear, shownMonth, 1 - offset + i));
        return out;
    }

    function changeMonth(delta) {
        const d = new Date(shownYear, shownMonth + delta, 1);
        shownYear = d.getFullYear();
        shownMonth = d.getMonth();
    }

    function goToday() {
        shownYear = today.getFullYear();
        shownMonth = today.getMonth();
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    // ISO 8601 week number.
    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        const yearStart = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - yearStart) / 86400000 + 1) / 7);
    }

    readonly property real cellSize: Math.round(Style.fontSize * 2.4)

    // Today, large.
    ColumnLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: Math.round(Style.fontSize * 0.3)
        spacing: 0

        VText {
            text: Qt.formatTime(root.today, root.use24h ? "HH:mm" : "h:mm AP")
            font.pixelSize: Style.fontSize * 2.4
            font.bold: true
        }
        VText {
            text: Qt.formatDate(root.today, "dddd d MMMM yyyy")
            color: Theme.textMuted
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.border
    }

    RowLayout {
        Layout.fillWidth: true

        VIconButton {
            iconName: "chevron-left"
            tooltip: "Previous month"
            onClicked: root.changeMonth(-1)
        }

        MouseArea {
            Layout.fillWidth: true
            implicitHeight: monthLabel.implicitHeight
            cursorShape: Qt.PointingHandCursor
            onClicked: root.goToday()

            VText {
                id: monthLabel
                anchors.centerIn: parent
                text: Qt.formatDate(new Date(root.shownYear, root.shownMonth, 1), "MMMM yyyy")
                font.bold: true
                font.pixelSize: Style.fontSize * 1.1
            }
        }

        VIconButton {
            iconName: "chevron-right"
            tooltip: "Next month"
            onClicked: root.changeMonth(1)
        }
    }

    // Weekday names, then the 6-week grid. Scrolling changes month.
    MouseArea {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: grid.implicitWidth
        implicitHeight: grid.implicitHeight
        acceptedButtons: Qt.NoButton

        property real wheelAccumulator: 0
        onWheel: wheel => {
            wheelAccumulator += wheel.angleDelta.y;
            while (Math.abs(wheelAccumulator) >= 120) {
                const dir = wheelAccumulator > 0 ? -1 : 1;
                wheelAccumulator += dir * 120;
                root.changeMonth(dir);
            }
        }

        GridLayout {
            id: grid
            columns: Settings.calendar.showWeekNumbers ? 8 : 7
            rowSpacing: 2
            columnSpacing: 2

            // Header row.
            Item {
                visible: Settings.calendar.showWeekNumbers
                implicitWidth: root.cellSize
                implicitHeight: Math.round(root.cellSize * 0.7)
            }
            Repeater {
                model: 7
                VText {
                    required property int index
                    Layout.preferredWidth: root.cellSize
                    Layout.preferredHeight: Math.round(root.cellSize * 0.7)
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().dayName((root.firstDay + index) % 7, Locale.ShortFormat).slice(0, 2)
                    color: Theme.textMuted
                    font.pixelSize: Style.fontSize * 0.85
                }
            }

            // Week rows: optional week number, then 7 days.
            Repeater {
                model: Settings.calendar.showWeekNumbers ? 48 : 42

                Item {
                    id: cell
                    required property int index
                    readonly property bool isWeek: Settings.calendar.showWeekNumbers && index % 8 === 0
                    readonly property int dayIndex: Settings.calendar.showWeekNumbers ? index - Math.floor(index / 8) - 1 : index
                    // A week row is numbered by its middle day, which is in the right ISO
                    // week whichever day the week starts on.
                    readonly property date day: root.days[isWeek ? dayIndex + 4 : dayIndex]
                    readonly property bool inMonth: day.getMonth() === root.shownMonth
                    readonly property bool isToday: root.sameDay(day, root.today)

                    implicitWidth: root.cellSize
                    implicitHeight: root.cellSize

                    Rectangle {
                        anchors.centerIn: parent
                        width: root.cellSize - 4
                        height: width
                        radius: width / 2
                        visible: cell.isToday && !cell.isWeek
                        color: Theme.accent
                    }

                    VText {
                        anchors.centerIn: parent
                        text: cell.isWeek ? root.isoWeek(cell.day) : cell.day.getDate()
                        color: cell.isWeek ? Theme.accent
                             : cell.isToday ? Theme.onAccent
                             : cell.inMonth ? Theme.text : Qt.alpha(Theme.textMuted, 0.6)
                        font.bold: cell.isToday
                        font.pixelSize: cell.isWeek ? Style.fontSize * 0.8 : Style.fontSize
                    }
                }
            }
        }
    }
}
