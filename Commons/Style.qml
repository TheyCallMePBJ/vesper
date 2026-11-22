pragma Singleton

import QtQuick
import Quickshell

// Sizes shared across the shell. Bar sizes come from the bar's own settings
// (which can differ per monitor), so those are functions.
Singleton {
    id: root

    readonly property real uiScale: Settings.appearance.uiScale > 0 ? Settings.appearance.uiScale : 1
    readonly property string fontFamily: Settings.appearance.fontFamily || Qt.application.font.family
    readonly property string monoFontFamily: Settings.appearance.monoFontFamily || "monospace"
    // Text weight everywhere (bold text stays bold).
    readonly property int fontWeight: ({ light: Font.Light, normal: Font.Normal, medium: Font.Medium, demibold: Font.DemiBold })[Settings.appearance.fontWeight] || Font.Medium

    readonly property real baseFontSize: 13

    // Base UI font size (panels, settings window).
    readonly property real fontSize: baseFontSize * uiScale

    // Height of a horizontal bar / width of a vertical bar, in px.
    function barThickness(height) {
        return Math.max(12, Math.round(Number(height) || 30));
    }

    function barFontSize(contentScale) {
        return baseFontSize * (contentScale > 0 ? contentScale : 1);
    }

    // Icon size for bar widgets on a bar of the given font size.
    function barIconSize(fontSize) {
        return Math.round(fontSize * 1.25);
    }

    readonly property int radius: 6
    readonly property int animationDuration: 150
}
