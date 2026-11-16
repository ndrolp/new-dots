import QtQuick
import QtTest
import "../services/AndroidDevices.js" as Android
import "../services/AndroidPairing.js" as Pairing

// Pairing a new Android device: the QR code's name, password and payload,
// the pairing services it announces over mDNS, what adb pair answered, and
// what the panel says when a paired Android device didn't connect.
TestCase {
    name: "AndroidPairing"

    // adb 37 prints one tab-separated line per service: name, type, address.
    readonly property string wirelessDebuggingOn: [
        "List of discovered mdns services",
        "adb-61291JEA326957-AbCdEf\t_adb-tls-connect._tcp\t192.168.1.44:37045",
        "adb-61291JEA326957-AbCdEf\t_adb-tls-pairing._tcp\t192.168.1.44:41233",
        "studio-Xy12Ab34\t_adb-tls-pairing._tcp\t192.168.1.50:39999",
        ""
    ].join("\n")

    // A stand-in for Math.random that walks through `values`.
    function randomFrom(values) {
        let index = 0;
        return () => values[index++ % values.length];
    }

    function test_eachQrCodeHasAFreshNameAndPassword() {
        const first = Pairing.qrPairing(randomFrom([0, 0.5, 0.99]));
        verify(/^studio-[A-Za-z0-9]{8}$/.test(first.name), first.name);
        verify(/^[A-Za-z0-9]{12}$/.test(first.password), first.password);
        const second = Pairing.qrPairing(randomFrom([0.25, 0.75]));
        verify(second.name !== first.name);
        verify(second.password !== first.password);
        // Math.random is what the panel passes.
        verify(Pairing.qrPairing(Math.random).name !== Pairing.qrPairing(Math.random).name);
    }

    function test_theQrCodeCarriesTheNameAndPasswordTheWayAndroidReadsThem() {
        compare(Pairing.qrPayload({ name: "studio-Xy12Ab34", password: "s3cretPass12" }),
            "WIFI:T:ADB;S:studio-Xy12Ab34;P:s3cretPass12;;");
    }

    function test_theAndroidDeviceThatScannedTheCodeAnnouncesItsName() {
        const services = Android.parseServices(wirelessDebuggingOn);
        compare(Pairing.pairingAddress(services, "studio-Xy12Ab34"), "192.168.1.50:39999");
        compare(Pairing.pairingAddress(services, "studio-Other"), "");
    }

    // While an Android device's "Pair device with pairing code" dialog is
    // open it announces a pairing service of its own, not the QR code's.
    function test_anAndroidDeviceShowingItsPairingCodeFillsTheAddress() {
        const services = Android.parseServices(wirelessDebuggingOn);
        compare(Pairing.codePairingAddress(services), "192.168.1.44:41233");
        compare(Pairing.codePairingAddress(Android.parseServices(
            "studio-Xy12Ab34\t_adb-tls-pairing._tcp\t192.168.1.50:39999\n")), "");
    }

    function test_aPairingCodeNeedsAnAddressAndSixDigits() {
        verify(Pairing.canPairWithCode("192.168.1.44:41233", "123456"));
        verify(Pairing.canPairWithCode(" 192.168.1.44:41233 ", " 123456 "));
        verify(!Pairing.canPairWithCode("192.168.1.44", "123456"));
        verify(!Pairing.canPairWithCode("192.168.1.44:41233", "12345"));
        verify(!Pairing.canPairWithCode("192.168.1.44:41233", "12345a"));
        verify(!Pairing.canPairWithCode("", ""));
    }

    function test_whatAdbPairAnswered() {
        compare(Pairing.pairedSerial(
            "Successfully paired to 192.168.1.44:41233 [guid=adb-61291JEA326957-AbCdEf]\n"), "61291JEA326957");
        compare(Pairing.pairedSerial("Failed: Wrong password or connection was dropped.\n"), "");
        compare(Pairing.pairProblem("Failed: Wrong password or connection was dropped.\n"),
            "Wrong password or connection was dropped.");
        compare(Pairing.pairProblem(""), "Couldn't pair with the phone");
    }

    // Paired, but connecting it failed or it never showed up: "Paired,
    // connecting…" gives way to why.
    function test_aPairedAndroidDeviceThatDidntConnectSaysWhy() {
        compare(Pairing.pairedButNotConnected("Pixel 10a", "unreachable"),
            "Paired with Pixel 10a, but couldn't connect: it didn't answer. Try Connect once Wireless debugging is on");
        compare(Pairing.pairedButNotConnected("Pixel 10a", "unpaired"),
            "Paired with Pixel 10a, but couldn't connect: it didn't accept this computer. Try pairing again");
        compare(Pairing.pairedButNotConnected("Pixel 10a", "unknown"),
            "Paired with Pixel 10a, but couldn't connect: adb didn't say why. Try Connect");
        compare(Pairing.pairedButNotConnected("61291JEA326957", "notAnnounced"),
            "Paired with 61291JEA326957, but couldn't connect: it didn't show up on the network. Try Connect once Wireless debugging is on");
    }
}
