import QtQuick
import qs.Components

BarWidget {
    implicitWidth: vertical ? 1 : options.size
    implicitHeight: vertical ? options.size : 1
}
