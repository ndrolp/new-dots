import QtQuick
import QtTest
import "../components/widgets" as Widgets
import "../components/widgets/CavaMedia.js" as CavaMedia

// What the Cava desktop widget shows of the player it follows: the media info
// and the track progress, as a line or painted on the bars, and the media
// info itself: cover, app icon badge, note fallback and the paused state.
TestCase {
    name: "CavaMedia"
    width: 400
    height: 200
    visible: true
    when: windowShown

    function player(state) {
        return Object.assign({
            exists: true, playing: true, stopped: false, position: 30, length: 120, lengthKnown: true
        }, state);
    }

    function test_theInfoShowsWhilePlayingOrPausedButNotStoppedOrWithoutAPlayer() {
        verify(CavaMedia.infoShown(player()));
        verify(CavaMedia.infoShown(player({ playing: false })));
        verify(!CavaMedia.infoShown(player({ playing: false, stopped: true })));
        verify(!CavaMedia.infoShown(player({ exists: false })));
        verify(!CavaMedia.infoShown(null));
    }

    function test_theLineShowsThePlayedFractionAlsoWhilePaused() {
        compare(CavaMedia.lineProgress("line", player()), 0.25);
        compare(CavaMedia.lineProgress("line", player({ playing: false })), 0.25);
        compare(CavaMedia.lineProgress("bars", player()), -1);
        compare(CavaMedia.lineProgress("off", player()), -1);
    }

    function test_theBarsShowProgressOnlyWhilePlaying() {
        compare(CavaMedia.barsProgress("bars", player()), 0.25);
        compare(CavaMedia.barsProgress("bars", player({ playing: false })), -1);
        compare(CavaMedia.barsProgress("line", player()), -1);
    }

    function test_withoutATrackLengthThereIsNoProgress() {
        compare(CavaMedia.lineProgress("line", player({ lengthKnown: false })), -1);
        compare(CavaMedia.lineProgress("line", player({ length: 0 })), -1);
        compare(CavaMedia.barsProgress("bars", player({ exists: false })), -1);
    }

    function test_theFractionStaysBetweenZeroAndOne() {
        compare(CavaMedia.lineProgress("line", player({ position: 200 })), 1);
        compare(CavaMedia.lineProgress("line", player({ position: -5 })), 0);
    }

    function test_theInfoSitsWithTheWidgetsColumn() {
        compare(CavaMedia.infoX("left", 300, 100), 0);
        compare(CavaMedia.infoX("center", 300, 100), 100);
        compare(CavaMedia.infoX("right", 300, 100), 200);
    }

    QtObject {
        id: appearance

        property int radius: 12
        property int textSize: 13
    }

    Component {
        id: mediaInfo

        Widgets.CavaMediaInfo {
            appearance: appearance
        }
    }

    function info(properties) {
        return createTemporaryObject(mediaInfo, this, properties);
    }

    function named(item, name) {
        if (item.objectName === name)
            return item;
        for (let i = 0; i < item.children.length; i++) {
            const found = named(item.children[i], name);
            if (found)
                return found;
        }
        return null;
    }

    function texts(item, found) {
        found = found || [];
        if (item.text !== undefined && item.visible && typeof item.text === "string")
            found.push(item.text);
        for (let i = 0; i < item.children.length; i++)
            texts(item.children[i], found);
        return found;
    }

    function test_itShowsTheTitleAndArtistWithTheirGlyphs() {
        const item = info({ title: "Song", artist: "Band" });

        verify(texts(item).indexOf("♪  Song") >= 0);
        verify(texts(item).indexOf("󰠃  Band") >= 0);
    }

    function test_theAlbumShowsUnderTheArtistOnlyWhenKnown() {
        verify(texts(info({ title: "Song", artist: "Band", album: "Record" })).indexOf("󰀥  Record") >= 0);
        compare(texts(info({ title: "Song", artist: "Band" })).filter(text => text.indexOf("󰀥") === 0), []);
    }

    function test_withNoCoverOrAppIconTheNoteFillsTheSquareInTheProgressColor() {
        const item = info({ title: "Song", noteColor: "red" });
        const note = named(item, "noteGlyph");

        verify(note.visible);
        verify(Qt.colorEqual(note.color, "red"));
        compare(item.height, item.coverSize);
    }

    function test_whilePausedThePauseGlyphShows() {
        const item = info({ title: "Song" });

        verify(!named(item, "pauseGlyph").visible);
        item.paused = true;
        verify(named(item, "pauseGlyph").visible);
    }

    function test_itIsNeverWiderThanItsRoom() {
        const item = info({ title: "A very long title that will not fit in the room it is given", maxWidth: 120 });

        compare(item.width, 120);
    }
}
