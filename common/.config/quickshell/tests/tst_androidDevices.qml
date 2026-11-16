import QtQuick
import QtTest
import "../services/AndroidDevices.js" as Android

// The Android devices panel's rules: what adb 37 prints for `adb devices -l`
// and `adb mdns services`, the rows it shows (one per Android device, live
// devices merged with known devices), the address Connect uses, what adb
// connect / pair answered, and the QR code's payload.
TestCase {
    name: "AndroidDevices"

    // Captured from a Pixel 10a over USB with adb 37.0.1.
    readonly property string pixelOverUsb: [
        "List of devices attached",
        "61291JEA326957         device usb:3-3 product:stallion model:Pixel_10a device:stallion transport_id:1",
        "",
        ""
    ].join("\n")

    function test_noDevicesListsNone() {
        compare(Android.parseDevices(""), []);
        compare(Android.parseDevices("List of devices attached\n\n"), []);
        compare(Android.parseDevices("* daemon not running; starting now at tcp:5037\n"
            + "* daemon started successfully\nList of devices attached\n\n"), []);
    }

    function test_aDeviceOverUsbIsReadWithItsModel() {
        compare(Android.parseDevices(pixelOverUsb), [{
            transport: "61291JEA326957",
            state: "device",
            usb: true,
            model: "Pixel 10a"
        }]);
    }

    function test_devicesOverTheNetworkAreNotUsb() {
        const devices = Android.parseDevices([
            "List of devices attached",
            "192.168.1.44:5555      device product:stallion model:Pixel_10a device:stallion transport_id:4",
            "adb-61291JEA326957-AbCdEf._adb-tls-connect._tcp device product:stallion model:Pixel_10a device:stallion transport_id:3",
            ""
        ].join("\n"));
        compare(devices.map(device => [device.transport, device.usb, device.model]), [
            ["192.168.1.44:5555", false, "Pixel 10a"],
            ["adb-61291JEA326957-AbCdEf._adb-tls-connect._tcp", false, "Pixel 10a"]
        ]);
    }

    function test_anUnauthorizedDeviceHasNoModel() {
        compare(Android.parseDevices("List of devices attached\n"
            + "61291JEA326957         unauthorized usb:3-3 transport_id:1\n"), [{
            transport: "61291JEA326957",
            state: "unauthorized",
            usb: true,
            model: ""
        }]);
    }

    // adb 37 prints one tab-separated line per service: name, type, address.
    readonly property string wirelessDebuggingOn: [
        "List of discovered mdns services",
        "adb-61291JEA326957-AbCdEf\t_adb-tls-connect._tcp\t192.168.1.44:37045",
        "adb-61291JEA326957-AbCdEf\t_adb-tls-pairing._tcp\t192.168.1.44:41233",
        "studio-Xy12Ab34\t_adb-tls-pairing._tcp\t192.168.1.50:39999",
        "adb-OTHER9-Zz9\t_adb._tcp\t192.168.1.60:5555",
        ""
    ].join("\n")

    function test_noServicesListsNone() {
        compare(Android.parseServices(""), []);
        compare(Android.parseServices("List of discovered mdns services\n\n"), []);
    }

    function test_connectAndPairingServicesAreReadWithTheirAddress() {
        compare(Android.parseServices(wirelessDebuggingOn), [
            { name: "adb-61291JEA326957-AbCdEf", type: "connect", address: "192.168.1.44:37045" },
            { name: "adb-61291JEA326957-AbCdEf", type: "pairing", address: "192.168.1.44:41233" },
            { name: "studio-Xy12Ab34", type: "pairing", address: "192.168.1.50:39999" }
        ]);
    }

    function test_theHardwareSerialIsReadFromAServiceOrTransportName() {
        compare(Android.serialOf("61291JEA326957"), "61291JEA326957");
        compare(Android.serialOf("adb-61291JEA326957-AbCdEf"), "61291JEA326957");
        compare(Android.serialOf("adb-61291JEA326957-AbCdEf._adb-tls-connect._tcp"), "61291JEA326957");
        // ip:port says nothing of the device; it stays as it is.
        compare(Android.serialOf("192.168.1.44:5555"), "192.168.1.44:5555");
    }

    readonly property var pixel: ({ serial: "61291JEA326957", model: "Pixel 10a", address: "192.168.1.44:5555" })

    function rowsOf(devicesText, servicesText, known, serials) {
        return Android.rows(Android.parseDevices(devicesText), Android.parseServices(servicesText),
            known || [], serials || {});
    }

    function test_aDeviceOverUsbIsOneConnectedRow() {
        const rows = rowsOf(pixelOverUsb, "");
        compare(rows.length, 1);
        compare(rows[0].serial, "61291JEA326957");
        compare(rows[0].name, "Pixel 10a");
        compare(rows[0].state, "usb");
        compare(rows[0].known, false);
        compare(Android.stateText(rows[0]), "Connected · USB");
    }

    function test_aDeviceOverUsbAndWifiIsOneRow() {
        const rows = rowsOf(pixelOverUsb
            + "adb-61291JEA326957-AbCdEf._adb-tls-connect._tcp device product:stallion model:Pixel_10a transport_id:3\n",
            wirelessDebuggingOn, [pixel]);
        compare(rows.length, 1);
        compare(rows[0].state, "both");
        compare(rows[0].wifi, ["adb-61291JEA326957-AbCdEf._adb-tls-connect._tcp"]);
        compare(Android.stateText(rows[0]), "USB + Wi-Fi");
    }

    function test_anIpPortConnectionBelongsToTheKnownDeviceAtThatAddress() {
        const rows = rowsOf("192.168.1.44:5555 device product:stallion model:Pixel_10a transport_id:4\n",
            "", [pixel]);
        compare(rows.length, 1);
        compare(rows[0].serial, "61291JEA326957");
        compare(rows[0].state, "wifi");
        compare(rows[0].known, true);
        compare(Android.stateText(rows[0]), "Connected · Wi-Fi");
    }

    function test_anIpPortConnectionBelongsToTheSerialItReported() {
        const rows = rowsOf(pixelOverUsb + "192.168.1.70:5555 device model:Pixel_10a transport_id:4\n",
            "", [], { "192.168.1.70:5555": "61291JEA326957" });
        compare(rows.length, 1);
        compare(rows[0].state, "both");
    }

    function test_anAnnouncedDeviceThatIsntConnectedIsAvailable() {
        const rows = rowsOf("", wirelessDebuggingOn);
        compare(rows.length, 1);
        compare(rows[0].serial, "61291JEA326957");
        // An unknown device's name isn't announced; its serial stands in.
        compare(rows[0].name, "61291JEA326957");
        compare(rows[0].state, "available");
        compare(Android.stateText(rows[0]), "Available");
    }

    function test_aKnownDeviceNoLongerVisibleIsNotSeen() {
        const rows = rowsOf("", "", [pixel]);
        compare(rows.length, 1);
        compare(rows[0].name, "Pixel 10a");
        compare(rows[0].state, "notSeen");
        compare(Android.stateText(rows[0]), "Not seen");
    }

    function test_aKnownDeviceThatIsAnnouncedIsAvailableUnderItsName() {
        const rows = rowsOf("", wirelessDebuggingOn, [pixel]);
        compare(rows.length, 1);
        compare(rows[0].name, "Pixel 10a");
        compare(rows[0].state, "available");
    }

    function test_anUnauthorizedUsbDeviceIsConnectedButNotAuthorized() {
        const rows = rowsOf("61291JEA326957 unauthorized usb:3-3 transport_id:1\n", "", [pixel]);
        compare(rows[0].name, "Pixel 10a");
        compare(rows[0].state, "usb");
        compare(rows[0].authorized, false);
    }

    function test_whatEachRowOffers() {
        const usb = rowsOf(pixelOverUsb, "")[0];
        compare(Android.actions(usb), ["connectWirelessly"]);
        const unauthorized = rowsOf("61291JEA326957 unauthorized usb:3-3 transport_id:1\n", "")[0];
        compare(Android.actions(unauthorized), []);
        const wifi = rowsOf("192.168.1.44:5555 device model:Pixel_10a\n", "", [pixel])[0];
        compare(Android.actions(wifi), ["disconnect", "forget"]);
        const both = rowsOf(pixelOverUsb + "192.168.1.44:5555 device model:Pixel_10a\n", "", [pixel])[0];
        compare(Android.actions(both), ["disconnect", "forget"]);
        compare(Android.actions(rowsOf("", wirelessDebuggingOn)[0]), ["connect"]);
        compare(Android.actions(rowsOf("", wirelessDebuggingOn, [pixel])[0]), ["connect", "forget"]);
        compare(Android.actions(rowsOf("", "", [pixel])[0]), ["connect", "forget"]);
    }

    function test_aDeviceConnectedOverTheNetworkIsRemembered() {
        const rows = rowsOf("adb-61291JEA326957-AbCdEf._adb-tls-connect._tcp device model:Pixel_10a\n",
            wirelessDebuggingOn);
        compare(Android.remembered([], rows),
            [{ serial: "61291JEA326957", model: "Pixel 10a", address: "192.168.1.44:37045" }]);
    }

    function test_aKnownDeviceKeepsItsLastAddress() {
        const moved = rowsOf("192.168.1.45:5555 device model:Pixel_10a\n", "", [pixel],
            { "192.168.1.45:5555": "61291JEA326957" });
        compare(Android.remembered([pixel], moved),
            [{ serial: "61291JEA326957", model: "Pixel 10a", address: "192.168.1.45:5555" }]);
        // Not seen, or only over USB, it stays as it was.
        compare(Android.remembered([pixel], rowsOf("", "", [pixel])), [pixel]);
        compare(Android.remembered([pixel], rowsOf(pixelOverUsb, "", [pixel])), [pixel]);
    }

    function test_onlyNetworkConnectionsAreRemembered() {
        compare(Android.remembered([], rowsOf(pixelOverUsb, wirelessDebuggingOn)), []);
    }

    function test_forgettingRemovesOnlyThatDevice() {
        const other = { serial: "OTHER", model: "Tab", address: "192.168.1.9:5555" };
        compare(Android.forgotten([pixel, other], "61291JEA326957"), [other]);
    }

    function test_connectTriesTheAnnouncedAddressThenTheLastOne() {
        const available = rowsOf("", wirelessDebuggingOn, [pixel])[0];
        compare(Android.connectAddresses(available, [pixel]), ["192.168.1.44:37045", "192.168.1.44:5555"]);
        const notSeen = rowsOf("", "", [pixel])[0];
        compare(Android.connectAddresses(notSeen, [pixel]), ["192.168.1.44:5555"]);
        const unknown = rowsOf("", wirelessDebuggingOn)[0];
        compare(Android.connectAddresses(unknown, []), ["192.168.1.44:37045"]);
        const same = { serial: pixel.serial, model: pixel.model, address: "192.168.1.44:37045" };
        compare(Android.connectAddresses(available, [same]), ["192.168.1.44:37045"]);
    }

    // What adb connect prints; it exits 0 when it fails too.
    function test_whatAdbConnectAnswered() {
        compare(Android.connectOutcome("connected to 192.168.1.44:37045\n"), "connected");
        compare(Android.connectOutcome("already connected to 192.168.1.44:5555\n"), "connected");
        compare(Android.connectOutcome("failed to connect to '192.168.1.44:5555': Connection refused\n"),
            "unreachable");
        compare(Android.connectOutcome("failed to connect to 192.168.1.44:5555\n"), "unreachable");
        compare(Android.connectOutcome("failed to authenticate to 192.168.1.44:37045\n"), "unpaired");
        compare(Android.connectOutcome(""), "unreachable");
    }

    function test_whatThePanelSaysWhenConnectFails() {
        compare(Android.connectProblem("unreachable"), "Turn on Wireless debugging on the phone");
        compare(Android.connectProblem("unpaired"), "Not paired with this computer: pair it below");
        compare(Android.connectProblem("connected"), "");
    }

    // After every address failed, not being paired says more than not answering.
    function test_theWorstOfSeveralAttemptsIsReported() {
        compare(Android.worstOutcome(["unreachable", "unpaired"]), "unpaired");
        compare(Android.worstOutcome(["unpaired", "unreachable"]), "unpaired");
        compare(Android.worstOutcome(["unreachable"]), "unreachable");
        compare(Android.worstOutcome([]), "unreachable");
    }

    // A stand-in for Math.random that walks through `values`.
    function randomFrom(values) {
        let index = 0;
        return () => values[index++ % values.length];
    }

    function test_eachQrCodeHasAFreshNameAndPassword() {
        const first = Android.qrPairing(randomFrom([0, 0.5, 0.99]));
        verify(/^studio-[A-Za-z0-9]{8}$/.test(first.name), first.name);
        verify(/^[A-Za-z0-9]{12}$/.test(first.password), first.password);
        const second = Android.qrPairing(randomFrom([0.25, 0.75]));
        verify(second.name !== first.name);
        verify(second.password !== first.password);
        // Math.random is what the panel passes.
        verify(Android.qrPairing(Math.random).name !== Android.qrPairing(Math.random).name);
    }

    function test_theQrCodeCarriesTheNameAndPasswordTheWayAndroidReadsThem() {
        compare(Android.qrPayload({ name: "studio-Xy12Ab34", password: "s3cretPass12" }),
            "WIFI:T:ADB;S:studio-Xy12Ab34;P:s3cretPass12;;");
    }

    function test_thePhoneThatScannedTheCodeAnnouncesItsName() {
        const services = Android.parseServices(wirelessDebuggingOn);
        compare(Android.pairingAddress(services, "studio-Xy12Ab34"), "192.168.1.50:39999");
        compare(Android.pairingAddress(services, "studio-Other"), "");
    }

    // While a phone's "Pair device with pairing code" dialog is open it
    // announces a pairing service of its own, not the QR code's.
    function test_aPhoneShowingItsPairingCodeFillsTheAddress() {
        const services = Android.parseServices(wirelessDebuggingOn);
        compare(Android.codePairingAddress(services), "192.168.1.44:41233");
        compare(Android.codePairingAddress(Android.parseServices(
            "studio-Xy12Ab34\t_adb-tls-pairing._tcp\t192.168.1.50:39999\n")), "");
    }

    function test_aPairingCodeNeedsAnAddressAndSixDigits() {
        verify(Android.canPairWithCode("192.168.1.44:41233", "123456"));
        verify(Android.canPairWithCode(" 192.168.1.44:41233 ", " 123456 "));
        verify(!Android.canPairWithCode("192.168.1.44", "123456"));
        verify(!Android.canPairWithCode("192.168.1.44:41233", "12345"));
        verify(!Android.canPairWithCode("192.168.1.44:41233", "12345a"));
        verify(!Android.canPairWithCode("", ""));
    }

    function test_whatAdbPairAnswered() {
        compare(Android.pairedSerial(
            "Successfully paired to 192.168.1.44:41233 [guid=adb-61291JEA326957-AbCdEf]\n"), "61291JEA326957");
        compare(Android.pairedSerial("Failed: Wrong password or connection was dropped.\n"), "");
        compare(Android.pairProblem("Failed: Wrong password or connection was dropped.\n"),
            "Wrong password or connection was dropped.");
        compare(Android.pairProblem(""), "Couldn't pair with the phone");
    }

    // `adb shell ip -f inet addr show wlan0`, captured from the Pixel 10a.
    function test_thePhonesWifiAddressIsReadFromIp() {
        compare(Android.wifiIp([
            "47: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000",
            "    inet 192.168.1.44/24 brd 192.168.1.255 scope global dynamic wlan0",
            "       valid_lft 83263sec preferred_lft 83263sec",
            ""
        ].join("\n")), "192.168.1.44");
        compare(Android.wifiIp(""), "");
        compare(Android.wifiIp("Device \"wlan0\" does not exist.\n"), "");
    }
}
