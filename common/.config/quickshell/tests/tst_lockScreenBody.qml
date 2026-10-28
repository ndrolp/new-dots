import QtQuick
import QtTest
import "../components/lock" as Lock

// What the lock screen shows on one monitor. Lock.qml puts it on every
// monitor with WlSessionLock and checks the password with PamContext, which
// don't load here, so these tests stop at the password it asks to check.
TestCase {
    name: "LockScreenBody"
    width: 800
    height: 600
    // Shown, so that `visible` tells what the lock screen shows.
    visible: true
    when: windowShown

    Component {
        id: bodyComponent

        Lock.LockScreenBody {
            width: 800
            height: 600
            now: new Date(2026, 9, 28, 9, 5)
        }
    }

    SignalSpy {
        id: submitted
        signalName: "passwordSubmitted"
    }

    function all(item, predicate, found) {
        found = found || [];
        if (predicate(item))
            found.push(item);
        for (let i = 0; i < item.children.length; i++)
            all(item.children[i], predicate, found);
        return found;
    }

    function shown(item, text) {
        return all(item, child => child.text === text && child.visible).length > 0;
    }

    function field(item) {
        return all(item, child => child.echoMode === TextInput.Password)[0];
    }

    function make(properties) {
        const body = createTemporaryObject(bodyComponent, this, properties || {});
        submitted.clear();
        submitted.target = body;
        return body;
    }

    function test_everyMonitorShowsTheClockAndTheDate() {
        const body = make({ showsPasswordField: false });
        verify(shown(body, "09:05"));
        verify(shown(body, "Wednesday, October 28"));
    }

    function test_onlyTheFocusedMonitorShowsThePasswordField() {
        verify(!field(make({ showsPasswordField: false })).visible);
        verify(field(make({ showsPasswordField: true })).visible);
    }

    function test_enterAsksToCheckThePasswordAndClearsTheField() {
        const body = make({ showsPasswordField: true });
        const input = field(body);

        input.forceActiveFocus();
        keyClick("h");
        keyClick("i");
        keyClick(Qt.Key_Return);

        compare(submitted.count, 1);
        compare(submitted.signalArguments[0][0], "hi");
        compare(input.text, "");
    }

    function test_whileAPasswordIsCheckedTheFieldTakesNothing() {
        const body = make({ showsPasswordField: true, checking: true });
        const input = field(body);

        input.forceActiveFocus();
        keyClick("h");
        keyClick(Qt.Key_Return);

        compare(input.text, "");
        compare(submitted.count, 0);
        verify(shown(body, "Checking…"));
    }

    function test_theErrorShowsUnderThePasswordField() {
        const body = make({ showsPasswordField: true, error: "Wrong password" });
        verify(shown(body, "Wrong password"));
    }

    function test_theErrorOnlyShowsWithThePasswordField() {
        const body = make({ showsPasswordField: false, error: "Wrong password" });
        verify(!shown(body, "Wrong password"));
    }
}
