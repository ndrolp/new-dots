import QtQuick
import QtTest
import "../config" as Config
import "../components/panels" as Panels

// The wallpapers of a folder, as the picker and the selector list them. A
// thumbnail always shows the file its row was listed from. The folder changes
// at startup, while the first listing is still loading (a monitor found to be
// portrait switches to the vertical folder): the old folder's rows still
// arrive, and no thumbnail tries their names in the new folder, where they
// may not exist.
TestCase {
    id: test

    name: "WallpaperFiles"

    readonly property string fixtureFolder: decodeURIComponent(
        Qt.resolvedUrl("fixtures/wallpapers").toString().slice(7))
    readonly property string horizontal: fixtureFolder + "/Horizontal"
    readonly property string vertical: fixtureFolder + "/Vertical"
    property string folder: ""
    property var tried: []

    Component {
        id: filesComponent

        Config.WallpaperFiles {}
    }

    // The thumbnails of the wallpapers in `test.folder`, as the picker and
    // the selector draw them; every file a thumbnail tries is in `tried`.
    Component {
        id: stripComponent

        Item {
            readonly property alias files: files
            readonly property alias thumbnails: thumbnails

            Config.WallpaperFiles {
                id: files

                path: test.folder
            }

            Repeater {
                id: thumbnails

                model: files
                delegate: Item {
                    required property string filePath

                    width: 10
                    height: 10

                    Panels.WallpaperThumbnail {
                        filePath: parent.filePath
                        decodeHeight: 10
                        asynchronous: false
                        onSourceChanged: test.tried = test.tried.concat([source.toString()])
                    }
                }
            }
        }
    }

    function init() {
        folder = "";
        tried = [];
    }

    function paths(files) {
        const listed = [];
        for (let index = 0; index < files.count; index++)
            listed.push(files.pathAt(index));
        return listed;
    }

    function fileUrl(path) {
        return "file://" + path;
    }

    function test_listsTheFolderWallpapersByPath() {
        const files = createTemporaryObject(filesComponent, this, { path: horizontal });

        tryCompare(files, "count", 2);
        compare(paths(files).sort(), [horizontal + "/Starry Night.png", horizontal + "/dunes.png"]);
    }

    function test_switchingFolderNeverTriesAMissingFile() {
        folder = horizontal;
        const strip = createTemporaryObject(stripComponent, this);

        folder = vertical;

        tryCompare(strip.files, "count", 1);
        compare(paths(strip.files), [vertical + "/tower.png"]);
        const existing = [horizontal + "/dunes.png", horizontal + "/Starry Night.png",
            vertical + "/tower.png"].map(path => fileUrl(path));
        for (const source of tried)
            verify(existing.includes(source), source);
        verify(tried.includes(fileUrl(vertical + "/tower.png")));
    }

    function test_noFolderListsNothing() {
        const files = createTemporaryObject(filesComponent, this, { path: "" });

        compare(files.count, 0);
        compare(files.pathAt(0), "");
    }
}
