import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config/Motion.js" as Motion

// The Motion section: reduce motion is a switch that makes every animation
// instant as soon as it is turned on.
TestCase {
    name: "MotionSettings"
    width: 800
    height: 600
    when: windowShown

    function all(item, predicate, found) {
        found = found || [];
        if (predicate(item))
            found.push(item);
        for (let i = 0; i < item.children.length; i++)
            all(item.children[i], predicate, found);
        return found;
    }

    function switchRow(item, label) {
        return all(item, child => child.label === label && child.switchItem !== undefined)[0];
    }

    // Where the settings panel shows a section. A fake appearance stands in
    // for the shell's; the section writes to it.
    Component {
        id: sectionArea

        Item {
            property alias appearance: appearance
            property alias section: section

            width: 700

            QtObject {
                id: appearance

                property int radius: 12
                property int textSize: 13
                readonly property var motion: Motion.motion(reduceMotion)
                property bool reduceMotion: false
            }

            Panels.MotionSettings {
                id: section

                appearance: appearance
            }
        }
    }

    function make() {
        const built = createTemporaryObject(sectionArea, this);
        return { appearance: built.appearance, item: built.section };
    }

    function test_reduceMotionIsASwitchShowingTheSavedSetting() {
        const built = make();
        const row = switchRow(built.item, "Reduce motion");

        verify(row);
        compare(row.checked, false);
    }

    function test_turningReduceMotionOnSavesItAndOffAgain() {
        const built = make();
        const row = switchRow(built.item, "Reduce motion");

        row.toggled();
        compare(built.appearance.reduceMotion, true);
        compare(row.checked, true);

        row.toggled();
        compare(built.appearance.reduceMotion, false);
    }
}
