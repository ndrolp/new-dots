import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config/Motion.js" as Motion
import "../services/AndroidDevices.js" as Android

// The device list of the Android devices panel: one row per Android device
// with its name and state, and the actions each one offers.
// AndroidDevicesPanel.qml (a Quickshell window) hands it the service's rows.
TestCase {
    name: "AndroidDevicesSection"
    width: 600
    height: 800
    visible: true
    when: windowShown

    QtObject {
        id: sampleAppearance

        property int radius: 12
        property int textSize: 13
        readonly property var motion: Motion.motion(false)
    }

    Component {
        id: sectionComponent

        Panels.AndroidDevicesSection {
            width: 500
            appearance: sampleAppearance
        }
    }

    SignalSpy {
        id: actionSpy

        signalName: "actionRequested"
    }

    readonly property var pixel: ({ serial: "61291JEA326957", model: "Pixel 10a", address: "192.168.1.44:5555" })

    function rowsOf(devicesText, servicesText, known) {
        return Android.rows(Android.parseDevices(devicesText), Android.parseServices(servicesText),
            known || [], {});
    }

    function make(properties) {
        const section = createTemporaryObject(sectionComponent, this, properties);
        actionSpy.clear();
        actionSpy.target = section;
        return section;
    }

    function all(item, predicate, found) {
        found = found || [];
        if (predicate(item))
            found.push(item);
        for (let i = 0; i < item.children.length; i++)
            all(item.children[i], predicate, found);
        if (item.contentItem && item.contentItem !== item)
            all(item.contentItem, predicate, found);
        return found;
    }

    function visibleIn(root, item) {
        for (let current = item; current && current !== root.parent; current = current.parent) {
            if (!current.visible)
                return false;
        }
        return true;
    }

    function shown(item, text) {
        return all(item, child => child.text === text && child.font !== undefined
            && visibleIn(item, child))[0] || null;
    }

    function button(item, label) {
        return all(item, child => child.label === label && child.activated !== undefined
            && visibleIn(item, child))[0] || null;
    }

    function test_withNoDevicesItSaysSo() {
        verify(shown(make({ rows: [] }), "No Android devices"));
    }

    function test_everyDeviceShowsItsNameAndState() {
        const section = make({ rows: rowsOf("61291JEA326957 device usb:3-3 model:Pixel_10a\n"
            + "192.168.1.9:5555 device model:Tab_S9\n", "",
            [{ serial: "TAB", model: "Tab S9", address: "192.168.1.9:5555" },
             { serial: "OLD", model: "Pixel 6", address: "192.168.1.30:5555" }]) });
        verify(!shown(section, "No Android devices"));
        verify(shown(section, "Pixel 10a"));
        verify(shown(section, "Connected · USB"));
        verify(shown(section, "Tab S9"));
        verify(shown(section, "Connected · Wi-Fi"));
        verify(shown(section, "Pixel 6"));
        verify(shown(section, "Not seen"));
    }

    function test_eachActionAsksForItWithItsRow() {
        const section = make({ rows: rowsOf("", "", [pixel]) });
        verify(!button(section, "Disconnect"));
        button(section, "Connect").activated();
        button(section, "Forget").activated();
        compare(actionSpy.count, 2);
        compare(actionSpy.signalArguments[0][0], "connect");
        compare(actionSpy.signalArguments[0][1].serial, "61291JEA326957");
        compare(actionSpy.signalArguments[1][0], "forget");
    }

    function test_aDeviceOverUsbOffersToConnectWirelessly() {
        const section = make({ rows: rowsOf("61291JEA326957 device usb:3-3 model:Pixel_10a\n", "") });
        button(section, "Connect wirelessly").activated();
        compare(actionSpy.signalArguments[0][0], "connectWirelessly");
    }

    function test_anUnauthorizedUsbDeviceAsksToAcceptThePrompt() {
        const section = make({ rows: rowsOf("61291JEA326957 unauthorized usb:3-3\n", "") });
        verify(!button(section, "Connect wirelessly"));
        verify(shown(section, "Accept the USB debugging prompt on the phone"));
    }

    function test_whileAnActionRunsTheButtonsWait() {
        const section = make({ rows: rowsOf("", "", [pixel]), busy: true });
        button(section, "Connect").activated();
        compare(actionSpy.count, 0);
    }

    function test_whatTheLastActionDidOrWhyItFailedIsShown() {
        verify(shown(make({ rows: [], message: "You can unplug it now" }), "You can unplug it now"));
        verify(shown(make({ rows: [], problem: "Turn on Wireless debugging on the phone" }),
            "Turn on Wireless debugging on the phone"));
    }

    // Without adb the panel only says why it can't work.
    function test_withoutAdbItSaysWhyAndHowToInstallIt() {
        const section = make({ rows: rowsOf("", "", [pixel]), unavailable: Android.missingAdb });
        verify(shown(section, Android.missingAdb));
        verify(/android-tools/.test(Android.missingAdb));
        verify(!shown(section, "Pixel 10a"));
        verify(!shown(section, "No Android devices"));
    }
}
