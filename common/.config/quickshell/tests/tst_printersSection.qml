import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config/Motion.js" as Motion

// The Printers heading of the Printers panel: every printer with its state,
// connection and whether it's the default, and opening one for *Set default*
// and *Remove*. PrintersPanel.qml (a Quickshell window) hands it the
// printers service's list.
TestCase {
    name: "PrintersSection"
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

        Panels.PrintersSection {
            width: 500
            appearance: sampleAppearance
        }
    }

    SignalSpy {
        id: defaultSpy

        signalName: "setDefaultRequested"
    }

    SignalSpy {
        id: removeSpy

        signalName: "removeRequested"
    }

    readonly property var twoPrinters: [
        { name: "Brother", description: "Brother HL-L2350DW", state: "printing", reason: "",
          connection: "network", isDefault: false },
        { name: "Zebra_Label", description: "", state: "error", reason: "Media jam",
          connection: "usb", isDefault: true }
    ]

    function make(printers) {
        const section = createTemporaryObject(sectionComponent, this, { printers: printers });
        defaultSpy.clear();
        removeSpy.clear();
        defaultSpy.target = section;
        removeSpy.target = section;
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

    // Shown within `root`: it and every item up to `root` are visible.
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

    function test_theHeadingIsPrinters() {
        verify(shown(make([]), "Printers"));
    }

    function test_withNoPrintersItSaysSo() {
        verify(shown(make([]), "No printers added"));
    }

    function test_everyPrinterShowsItsStateConnectionAndDefault() {
        const section = make(twoPrinters);
        verify(!shown(section, "No printers added"));
        verify(shown(section, "Brother"));
        verify(shown(section, "Printing · Network"));
        verify(shown(section, "Zebra_Label"));
        verify(shown(section, "Error: Media jam · USB"));
        verify(shown(section, "Default"));
        compare(all(section, child => child.text === "Default" && visibleIn(section, child)).length, 1);
    }

    function test_openingAPrinterOffersSetDefaultAndRemove() {
        const section = make(twoPrinters);
        verify(!button(section, "Set default"));

        section.expanded = "Brother";
        const setDefault = button(section, "Set default");
        verify(setDefault);
        setDefault.activated();
        compare(defaultSpy.count, 1);
        compare(defaultSpy.signalArguments[0][0], "Brother");
    }

    function test_theDefaultPrinterHasNoSetDefault() {
        const section = make(twoPrinters);
        section.expanded = "Zebra_Label";
        verify(!button(section, "Set default"));
        verify(button(section, "Remove"));
    }

    // Removing asks once more before it goes.
    function test_removeAsksBeforeRemoving() {
        const section = make(twoPrinters);
        section.expanded = "Brother";

        button(section, "Remove").activated();
        compare(removeSpy.count, 0);
        verify(shown(section, "Remove Brother?"));

        button(section, "Cancel").activated();
        verify(!shown(section, "Remove Brother?"));

        button(section, "Remove").activated();
        button(section, "Yes, remove").activated();
        compare(removeSpy.count, 1);
        compare(removeSpy.signalArguments[0][0], "Brother");
    }

    function test_aProblemReadingPrintersIsShown() {
        const section = make([]);
        section.failure = "Scheduler is not running.";
        verify(shown(section, "Scheduler is not running."));
        verify(!shown(section, "No printers added"));
    }
}
