pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import qs.Commons

// Which wallpaper each monitor shows, and the images in the wallpaper folder.
// Vesper draws the wallpaper itself (Modules/Wallpaper), but only once one has
// been chosen, so whatever drew it before keeps working until then.
Singleton {
    id: root

    readonly property bool enabled: Settings.wallpaper.enabled !== false
    readonly property string directory: expand(Settings.wallpaper.directory || "")
    readonly property var paths: Settings.wallpaper.paths || ({})

    // Images in `directory`: [{ path, name }], sorted by name.
    property var images: []

    function expand(path) {
        const p = String(path).trim();
        if (p === "~" || p.startsWith("~/"))
            return Quickshell.env("HOME") + p.slice(1);
        return p;
    }

    // file:// URL for a path, with characters like # and ? escaped.
    function fileUrl(path) {
        return path ? "file://" + path.split("/").map(encodeURIComponent).join("/") : "";
    }

    // The image a monitor shows, or "" for none.
    function pathFor(screenName) {
        return paths[screenName] || paths[""] || "";
    }

    // Set the wallpaper for one monitor, or every monitor when they're kept
    // the same (or no monitor is given).
    function set(path, screenName) {
        if (Settings.wallpaper.sameOnAllMonitors !== false || !screenName) {
            Settings.set("wallpaper.paths", { "": path });
        } else {
            const next = Object.assign({}, paths);
            next[screenName] = path;
            Settings.set("wallpaper.paths", next);
        }
    }

    function random(screenName) {
        const current = pathFor(screenName || "");
        const choices = images.filter(i => i.path !== current);
        if (choices.length > 0)
            set(choices[Math.floor(Math.random() * choices.length)].path, screenName);
    }

    // Stop drawing a wallpaper (whatever is underneath shows again).
    function clear() {
        Settings.set("wallpaper.paths", {});
    }

    FolderListModel {
        id: folder
        folder: root.fileUrl(root.directory)
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp", "*.gif", "*.JPG", "*.JPEG", "*.PNG", "*.WEBP"]
        showDirs: false
        showHidden: false
        sortField: FolderListModel.Name
        caseSensitive: false

        onStatusChanged: if (status === FolderListModel.Ready) root.updateImages()
        onCountChanged: root.updateImages()
    }

    function updateImages() {
        const out = [];
        for (let i = 0; i < folder.count; i++)
            out.push({ path: folder.get(i, "filePath"), name: folder.get(i, "fileBaseName") });
        images = out;
    }
}
