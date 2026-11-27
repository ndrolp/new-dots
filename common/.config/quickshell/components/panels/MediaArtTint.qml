import Quickshell
import Quickshell.Io
import QtQuick
import "MediaCard.js" as MediaCard

// The one colour a track's art tints the capsule's media with
// (MediaCard.artTint), and what reads on it (MediaCard.onTint): the media
// popup inside a capsule (CapsuleMediaView.qml) and the capsule glance's
// media card. ColorQuantizer reads the art from MediaCard.artSource: local
// art as it is, web art (Spotify's) from its copy in the art cache, once
// fetched. With no art it is the accent.
Item {
    id: root

    // The track's art URL, "" for none.
    property string artUrl: ""
    // Whether the art shows: until it does, the tint is the accent.
    property bool artShown: false
    // The colorscheme (config/Theme.qml): its accent, background and text.
    required property var theme

    readonly property color tint: MediaCard.artTint(quantizer.colors, artShown, theme.accent)
    // What reads on the tint: the colorscheme's background or text, whichever
    // stands out on it.
    readonly property color onTint: MediaCard.onTint(tint, theme)
    readonly property var artFile: MediaCard.artSource(artUrl,
        MediaCard.artCacheDir(Quickshell.env("XDG_CACHE_HOME"), Quickshell.env("HOME")))
    // The art the quantizer reads now: web art only once its copy is there.
    property string quantizedArt: ""

    onArtFileChanged: fetchArt()
    Component.onCompleted: fetchArt()

    // Hands the art to the quantizer, fetching web art first; a fetch still
    // running for earlier art fetches this one once it ends.
    function fetchArt() {
        if (!artFile.fetch) {
            quantizedArt = artFile.source;
            return;
        }
        quantizedArt = "";
        if (artFetch.running)
            return;
        artFetch.fetched = artFile;
        artFetch.running = true;
    }

    ColorQuantizer {
        id: quantizer

        source: root.quantizedArt
        depth: 2
        rescaleSize: 64
    }

    // Fetches web art into the art cache, unless its copy is already there,
    // then hands it to the quantizer if it is still the track's art.
    Process {
        id: artFetch

        property var fetched: null

        command: ["sh", "-c",
            "[ -s \"$2\" ] && exit 0; mkdir -p \"$(dirname \"$2\")\" "
                + "&& curl -sfL --max-time 15 -o \"$2.part\" \"$1\" && mv -f \"$2.part\" \"$2\"",
            "art-fetch", fetched ? fetched.url : "", fetched ? fetched.path : ""]

        onExited: exitCode => {
            if (fetched !== root.artFile)
                Qt.callLater(root.fetchArt);
            else if (exitCode === 0)
                root.quantizedArt = fetched.source;
        }
    }
}
