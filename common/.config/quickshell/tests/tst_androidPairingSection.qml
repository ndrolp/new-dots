import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config/Motion.js" as Motion

// The Android devices panel's *Pair new device* section: the QR code by
// default, and a pairing code typed with the phone's address, filled from
// mDNS while its pairing dialog is open. AndroidDevicesPanel.qml hands it
// what the service has.
TestCase {
    name: "AndroidPairingSection"
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

        Panels.AndroidPairingSection {
            width: 500
            appearance: sampleAppearance
        }
    }

    SignalSpy {
        id: pairSpy

        signalName: "pairWithCodeRequested"
    }

    function make(properties) {
        const section = createTemporaryObject(sectionComponent, this, properties);
        pairSpy.clear();
        pairSpy.target = section;
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

    function field(item, placeholder) {
        return all(item, child => child.placeholderText === placeholder && visibleIn(item, child))[0] || null;
    }

    function qrCode(item) {
        return all(item, child => child.objectName === "qrCode" && visibleIn(item, child))[0] || null;
    }

    function link(item) {
        return all(item, child => child.objectName === "modeLink" && visibleIn(item, child))[0] || null;
    }

    // Drawn by qrencode from WIFI:T:ADB;S:studio-Xy12Ab34;P:s3cretPass12;;
    readonly property string image: Qt.resolvedUrl("fixtures/android-pairing-qr.png")

    function test_theQrCodeIsShownByDefault() {
        const section = make({ qrImage: image });
        verify(shown(section, "Pair new device"));
        const code = qrCode(section);
        verify(code);
        compare(String(code.source), image);
        verify(!field(section, "IP address and port"));
    }

    function test_aPairingCodeLinkSwitchesToTheFields() {
        const section = make({ qrImage: image });
        verify(shown(section, "Use a pairing code"));
        link(section).activated();
        verify(!qrCode(section));
        verify(field(section, "IP address and port"));
        verify(field(section, "6-digit code"));
        verify(shown(section, "Use a QR code"));
        link(section).activated();
        verify(qrCode(section));
    }

    function test_theAddressIsFilledFromThePhonesPairingDialog() {
        const section = make({ qrImage: image });
        link(section).activated();
        section.codeAddress = "192.168.1.44:41233";
        compare(field(section, "IP address and port").text, "192.168.1.44:41233");
    }

    function test_aTypedAddressAndCodePair() {
        const section = make({ qrImage: image });
        link(section).activated();
        const address = field(section, "IP address and port");
        const code = field(section, "6-digit code");
        address.text = "192.168.1.50:37001";
        address.textEdited();
        verify(!button(section, "Pair").interactive);
        code.text = "123456";
        code.textEdited();
        verify(button(section, "Pair").interactive);
        button(section, "Pair").activated();
        compare(pairSpy.count, 1);
        compare(pairSpy.signalArguments[0][0], "192.168.1.50:37001");
        compare(pairSpy.signalArguments[0][1], "123456");
        // A typed address isn't replaced by what mDNS finds afterwards.
        section.codeAddress = "192.168.1.44:41233";
        compare(address.text, "192.168.1.50:37001");
    }

    function test_onceAPhonePairsTheQrCodeGoes() {
        const section = make({ qrImage: image, paired: true, message: "Paired with Pixel 10a" });
        verify(!qrCode(section));
        verify(shown(section, "Paired with Pixel 10a"));
    }

    function test_whyPairingFailedIsShown() {
        const section = make({ qrImage: image, problem: "Wrong password or connection was dropped." });
        verify(shown(section, "Wrong password or connection was dropped."));
        const missing = make({ qrImage: "", qrProblem: "qrencode isn't installed" });
        verify(!qrCode(missing));
        verify(shown(missing, "qrencode isn't installed"));
    }
}
