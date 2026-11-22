import QtQuick
import QtTest
import "../components/bar" as Bar
import "../components/panels/MediaCard.js" as MediaCard
import "../config/Motion.js" as Motion

// The media view inside a capsule and the media live element at rest: the
// one colour quantized from the art that tints the view, and what moves the
// live element's bars.
TestCase {
    name: "MediaCapsule"

    readonly property var accent: ({ r: 0.5, g: 0.6, b: 0.9 })

    function test_withNoArtTheTintIsTheAccent() {
        compare(MediaCard.artTint([{ r: 1, g: 0, b: 0 }], false, accent), accent);
        compare(MediaCard.artTint([], true, accent), accent);
        compare(MediaCard.artTint(null, true, accent), accent);
    }

    function test_withArtTheTintIsItsMostColourfulColour() {
        const grey = { r: 0.5, g: 0.5, b: 0.5 };
        const dullRed = { r: 0.4, g: 0.25, b: 0.25 };
        const orange = { r: 0.95, g: 0.55, b: 0.1 };
        const nearBlack = { r: 0.08, g: 0.05, b: 0.05 };

        compare(MediaCard.artTint([grey, dullRed, orange, nearBlack], true, accent), orange);
        compare(MediaCard.artTint([grey], true, accent), grey);
    }

    // What reads on the tint (the play button's glyph): of the
    // colorscheme's background and text, the one further from the tint in
    // lightness, so light on a dark tint and dark on a light one.
    function test_whatReadsOnTheTintIsTheThemesBackgroundOrText_data() {
        const dark = { r: 0.1, g: 0.1, b: 0.12 };
        const light = { r: 0.92, g: 0.92, b: 0.9 };
        return [
            { tag: "light tint, dark theme", tint: { r: 0.95, g: 0.85, b: 0.4 },
                colours: { background: dark, text: light }, reads: "background" },
            { tag: "dark tint, dark theme", tint: { r: 0.2, g: 0.1, b: 0.4 },
                colours: { background: dark, text: light }, reads: "text" },
            { tag: "light tint, light theme", tint: { r: 0.95, g: 0.85, b: 0.4 },
                colours: { background: light, text: dark }, reads: "text" },
            { tag: "dark tint, light theme", tint: { r: 0.2, g: 0.1, b: 0.4 },
                colours: { background: light, text: dark }, reads: "background" }
        ];
    }

    function test_whatReadsOnTheTintIsTheThemesBackgroundOrText(data) {
        compare(MediaCard.onTint(data.tint, data.colours), data.colours[data.reads]);
    }

    // What ColorQuantizer reads the art from: local art as it is; art on the
    // web (Spotify's) from a copy fetched into the art cache, named by a hash
    // of its URL so the same art is fetched once.
    function test_localArtIsQuantizedAsItIs_data() {
        return [
            { tag: "file URL", url: "file:///tmp/cover.png" },
            { tag: "path", url: "/tmp/cover.png" }
        ];
    }

    function test_localArtIsQuantizedAsItIs(data) {
        compare(MediaCard.artSource(data.url, "/home/me/.cache/quickshell/art"),
            { source: data.url, fetch: null });
    }

    function test_webArtIsFetchedIntoTheCacheFirst() {
        const url = "https://i.scdn.co/image/ab67616d0000b273e8b066f70c206551210d902b";
        const art = MediaCard.artSource(url, "/home/me/.cache/quickshell/art");

        verify(/^\/home\/me\/\.cache\/quickshell\/art\/[0-9a-f]{8,}$/.test(art.fetch.path), art.fetch.path);
        compare(art.fetch.url, url);
        compare(art.source, "file://" + art.fetch.path);
    }

    function test_theSameWebArtIsTheSameCacheFile() {
        const cache = "/c";
        const one = MediaCard.artSource("https://i.scdn.co/image/aaa", cache).fetch.path;

        compare(MediaCard.artSource("https://i.scdn.co/image/aaa", cache).fetch.path, one);
        verify(MediaCard.artSource("https://i.scdn.co/image/aab", cache).fetch.path !== one);
        verify(MediaCard.artSource("http://i.scdn.co/image/aaa", cache).fetch.path !== one);
    }

    function test_noArtIsNothingToQuantize() {
        compare(MediaCard.artSource("", "/c"), { source: "", fetch: null });
        compare(MediaCard.artSource(undefined, "/c"), { source: "", fetch: null });
    }

    // Where fetched art is kept: under the user's cache, XDG_CACHE_HOME or
    // else ~/.cache.
    function test_theArtCacheIsUnderTheUsersCache() {
        compare(MediaCard.artCacheDir("/x/cache", "/home/me"), "/x/cache/quickshell/art");
        compare(MediaCard.artCacheDir("", "/home/me"), "/home/me/.cache/quickshell/art");
    }

    function test_theLiveBarsAreCavasWhileItWorks() {
        compare(MediaCard.liveBars(true, ""), { source: "cava", moving: true });
    }

    function test_whenCavaFailsTheLiveBarsAreAnEqualiser() {
        compare(MediaCard.liveBars(true, "cava isn't installed, so the bars stay flat."),
            { source: "equaliser", moving: true });
    }

    function test_theEqualiserStopsWhilePaused() {
        compare(MediaCard.liveBars(false, "cava failed to start, so the bars stay flat."),
            { source: "equaliser", moving: false });
    }

    function test_theEqualiserDrawsEveryBarVisiblyButNeverFull() {
        for (let step = 0; step < 40; step++) {
            const frame = MediaCard.equaliserFrame(5, step);
            compare(frame.length, 5);
            verify(frame.every(height => height >= 0.2 && height <= 0.9), JSON.stringify(frame));
        }
    }

    function test_theEqualiserMovesFromOneStepToTheNext() {
        verify(JSON.stringify(MediaCard.equaliserFrame(5, 3)) !== JSON.stringify(MediaCard.equaliserFrame(5, 4)));
        compare(MediaCard.equaliserFrame(5, 3), MediaCard.equaliserFrame(5, 3));
    }

    // Stands in for the shared cava (services/Cava.qml).
    Component {
        id: fakeCava

        QtObject {
            property string failureHint: ""
            property var heights: [0.1, 0.2, 0.3, 0.4]
            property var drawnElements: []

            function setDrawing(element, drawing) {
                const others = drawnElements.filter(entry => entry !== element);
                drawnElements = drawing ? others.concat([element]) : others;
            }
        }
    }

    Component {
        id: liveBarsComponent

        Bar.MediaLiveBars {
            height: 12
            barCount: 4
            motion: Motion.motion(false)
        }
    }

    function liveBars(properties) {
        return createTemporaryObject(liveBarsComponent, this, properties);
    }

    function test_whileDrawnTheLiveBarsKeepTheSharedCavaRunning() {
        const cava = fakeCava.createObject(this);
        const bars = liveBars({ cava: cava, playing: true, drawing: true });

        compare(cava.drawnElements, [bars]);
        bars.drawing = false;
        compare(cava.drawnElements, []);
    }

    function test_whileCavaWorksTheLiveBarsDrawItsFrame() {
        const cava = fakeCava.createObject(this);
        const bars = liveBars({ cava: cava, playing: true, drawing: true });

        compare(bars.frame, [0.1, 0.2, 0.3, 0.4]);
    }

    function test_whenCavaFailsTheEqualiserMovesWhilePlayingAndStopsWhilePaused() {
        const cava = fakeCava.createObject(this, { failureHint: "cava isn't installed, so the bars stay flat." });
        const bars = liveBars({ cava: cava, playing: true, drawing: true });
        const first = JSON.stringify(bars.frame);

        tryVerify(() => JSON.stringify(bars.frame) !== first, 1000);
        bars.playing = false;
        const paused = JSON.stringify(bars.frame);
        wait(400);
        compare(JSON.stringify(bars.frame), paused);
    }

    // Reduce motion stops the equaliser, playing or not.
    function test_reduceMotionStopsTheEqualiser() {
        const cava = fakeCava.createObject(this, { failureHint: "cava isn't installed, so the bars stay flat." });
        const bars = liveBars({ cava: cava, playing: true, drawing: true, motion: Motion.motion(true) });
        const still = JSON.stringify(bars.frame);

        wait(400);
        compare(JSON.stringify(bars.frame), still);
    }
}
