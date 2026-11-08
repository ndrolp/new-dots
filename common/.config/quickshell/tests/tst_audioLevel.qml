import QtQuick
import QtTest
import "../components/bar" as Bar

// What the audio bar element shows (its icon and the volume meter or
// percentage) and how wide it is: the element is as wide as this plus the
// same side padding as battery, clock and media.
TestCase {
    name: "AudioLevel"
    width: 400
    height: 400
    // A row only lays out again what is shown, as in the bar.
    visible: true
    when: windowShown

    QtObject {
        id: barAppearance

        property int textSize: 13
        property int iconSize: 13
    }

    Component {
        id: audioLevel

        Bar.AudioLevel {
            appearance: barAppearance
        }
    }

    function level(properties) {
        return createTemporaryObject(audioLevel, this, properties);
    }

    // The first Text under `item` whose text passes `test`.
    function textOf(item, test) {
        if (item.text !== undefined && test(item.text))
            return item;
        for (let i = 0; i < item.children.length; i++) {
            const found = textOf(item.children[i], test);
            if (found)
                return found;
        }
        return null;
    }

    function test_aBiggerIconKeepsThePercentageCentredOnIt() {
        barAppearance.iconSize = 20;
        const item = level({ meterVisible: false, volume: 0.6, muted: false });
        const percentage = textOf(item, text => text === "60%");
        const icon = textOf(item, text => text === "󰕾");

        waitForRendering(item);
        fuzzyCompare(percentage.mapToItem(item, 0, percentage.height / 2).y,
            icon.mapToItem(item, 0, icon.height / 2).y, 0.5);
        barAppearance.iconSize = 13;
    }

    function test_withTheMeterHiddenItFitsThePercentage() {
        const low = level({ meterVisible: false, volume: 0.05, muted: false });
        const full = level({ meterVisible: false, volume: 1, muted: false });
        const meter = level({ meterVisible: true, volume: 0.05, muted: false });

        verify(low.implicitWidth < full.implicitWidth,
            "\"5%\" should take less room than \"100%\"");
        verify(low.implicitWidth < meter.implicitWidth,
            "\"5%\" should take less room than the meter");
    }

    function test_withTheMeterShownTheVolumeDoesNotChangeTheWidth() {
        const low = level({ meterVisible: true, volume: 0.05, muted: false });
        const full = level({ meterVisible: true, volume: 1, muted: false });

        compare(low.implicitWidth, full.implicitWidth);
    }

    function test_mutingDoesNotChangeTheWidthWithTheMeterShown() {
        const unmuted = level({ meterVisible: true, volume: 0.5, muted: false });
        const muted = level({ meterVisible: true, volume: 0.5, muted: true });

        verify(unmuted.implicitWidth > 0);
        compare(muted.implicitWidth, unmuted.implicitWidth);
    }

    function test_switchingTheMeterResizesRightAway() {
        const item = level({ meterVisible: true, volume: 0.05, muted: false });
        const withMeter = item.implicitWidth;

        // The row lays itself out before the next frame is drawn.
        item.meterVisible = false;
        tryVerify(() => item.implicitWidth < withMeter);

        item.meterVisible = true;
        tryCompare(item, "implicitWidth", withMeter);
    }
}
