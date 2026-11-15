import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config/Motion.js" as Motion

// The Discovered printers heading of the Printers panel: the printers found
// on the network and USB that aren't added, each with *Add*, why one can't
// be added driverless, and why none can be found. PrintersPanel.qml (a
// Quickshell window) hands it the discovered printers service's list.
TestCase {
    name: "DiscoveredPrintersSection"
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

        Panels.DiscoveredPrintersSection {
            width: 500
            appearance: sampleAppearance
        }
    }

    SignalSpy {
        id: addSpy

        signalName: "addRequested"
    }

    SignalSpy {
        id: settingsSpy

        signalName: "printSettingsRequested"
    }

    readonly property var laser: ({ key: "laser", model: "HP LaserJet Pro M404", service: "HP LaserJet Pro M404 [A1B2C3]",
        connection: "network", uri: "dnssd://x", driverless: true })
    readonly property var inkjet: ({ key: "inkjet", model: "EPSON ET-2850 Series", service: "EPSON ET-2850 Series (USB)",
        connection: "usb", uri: "ipp://localhost:60000/ipp/print", driverless: true })
    readonly property var oldLaser: ({ key: "old", model: "Kyocera FS-1020D", service: "Kyocera FS-1020D",
        connection: "network", uri: "dnssd://y", driverless: false })

    function make(discovered) {
        const section = createTemporaryObject(sectionComponent, this, { discovered: discovered });
        addSpy.clear();
        settingsSpy.clear();
        addSpy.target = section;
        settingsSpy.target = section;
        return section;
    }

    function all(item, predicate, found) {
        found = found || [];
        if (predicate(item))
            found.push(item);
        for (let i = 0; i < item.children.length; i++)
            all(item.children[i], predicate, found);
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

    function buttons(item, label) {
        return all(item, child => child.label === label && child.activated !== undefined
            && visibleIn(item, child));
    }

    function test_theHeadingIsDiscoveredPrinters() {
        verify(shown(make([]), "Discovered printers"));
    }

    function test_withNothingFoundItSaysItsLooking() {
        verify(shown(make([]), "Looking for printers…"));
    }

    function test_everyDiscoveredPrinterShowsHowItsConnected() {
        const section = make([inkjet, laser]);
        verify(!shown(section, "Looking for printers…"));
        verify(shown(section, "EPSON ET-2850 Series"));
        verify(shown(section, "USB"));
        verify(shown(section, "HP LaserJet Pro M404"));
        verify(shown(section, "Network"));
    }

    function test_addAddsThatPrinter() {
        const section = make([inkjet, laser]);
        const adds = buttons(section, "Add");
        compare(adds.length, 2);
        adds[1].activated();
        compare(addSpy.count, 1);
        compare(addSpy.signalArguments[0][0].key, "laser");
    }

    function test_whileAddingThePrinterWaits() {
        const section = make([laser]);
        section.addState = { adding: "laser", failedKey: "", failure: "" };
        verify(shown(section, "Adding…"));
        compare(buttons(section, "Add").length, 0);
    }

    function test_aPrinterThatCantPrintDriverlessOffersPrintSettings() {
        const section = make([oldLaser]);
        verify(shown(section, "Network · Can't print driverless"));
        compare(buttons(section, "Add").length, 0);
        buttons(section, "Print settings")[0].activated();
        compare(settingsSpy.count, 1);
    }

    function test_aFailedAddShowsWhyAndOffersPrintSettings() {
        const section = make([laser, inkjet]);
        section.addState = { adding: "", failedKey: "laser",
            failure: "Couldn't add HP LaserJet Pro M404 driverless: Unable to query printer" };
        verify(shown(section, "Couldn't add HP LaserJet Pro M404 driverless: Unable to query printer"));
        compare(buttons(section, "Print settings").length, 1);
        buttons(section, "Print settings")[0].activated();
        compare(settingsSpy.count, 1);
    }

    function test_whyNoPrintersCanBeFoundIsShown() {
        const section = make([]);
        section.problem = "avahi-daemon isn't running";
        verify(shown(section, "avahi-daemon isn't running"));
        verify(!shown(section, "Looking for printers…"));
    }
}
