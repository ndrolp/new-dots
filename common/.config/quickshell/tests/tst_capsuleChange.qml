import QtQuick
import QtTest
import "../components/bar"

// A change (volume, brightness, Caps Lock, audio output, bar profile or
// keep-awake) expands the focused monitor's capsule for about 1.5 s to show
// only that change; another one keeps it open and shows the newer one.
TestCase {
    name: "CapsuleChange"

    Component {
        id: changeComponent

        CapsuleChange {}
    }

    function capsuleChange() {
        return createTemporaryObject(changeComponent, this);
    }

    function test_itShowsNothingAtFirst() {
        const capsule = capsuleChange();

        compare(capsule.showing, false);
        compare(capsule.change, null);
    }

    // It shows the change at once, and for about 1.5 s.
    function test_itShowsAChangeForAboutOneAndAHalfSeconds() {
        const capsule = capsuleChange();
        const change = { kind: "volume", level: 0.4, muted: false };

        capsule.show(change);
        compare(capsule.showing, true);
        compare(capsule.change, change);
        wait(1300);
        compare(capsule.showing, true);
        tryCompare(capsule, "showing", false, 500);
    }

    // Holding a volume key: each change keeps it open another 1.5 s and shows
    // the newest level.
    function test_repeatedChangesKeepItOpenAndUpdateIt() {
        const capsule = capsuleChange();

        capsule.show({ kind: "volume", level: 0.4, muted: false });
        wait(1000);
        capsule.show({ kind: "volume", level: 0.45, muted: false });
        wait(1000);
        compare(capsule.showing, true);
        compare(capsule.change.level, 0.45);
        tryCompare(capsule, "showing", false, 800);
    }
}
