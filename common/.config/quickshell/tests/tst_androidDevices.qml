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

    function test_onlyRowsWithANetworkConnectionAreConnectedOverTheNetwork() {
        verify(Android.connectedOverNetwork(rowsOf("192.168.1.44:5555 device model:Pixel_10a\n", "", [pixel])[0]));
        verify(Android.connectedOverNetwork(
            rowsOf(pixelOverUsb + "192.168.1.44:5555 device model:Pixel_10a\n", "", [pixel])[0]));
        verify(!Android.connectedOverNetwork(rowsOf(pixelOverUsb, "")[0]));
        verify(!Android.connectedOverNetwork(rowsOf("", wirelessDebuggingOn)[0]));
        verify(!Android.connectedOverNetwork(rowsOf("", "", [pixel])[0]));
    }

    function test_whatEachRowOffers() {
        const usb = rowsOf(pixelOverUsb, "")[0];
        compare(Android.actions(usb), ["connectWirelessly"]);
        const unauthorized = rowsOf("61291JEA326957 unauthorized usb:3-3 transport_id:1\n", "")[0];
        compare(Android.actions(unauthorized), []);
        const wifi = rowsOf("192.168.1.44:5555 device model:Pixel_10a\n", "", [pixel])[0];
        // Connected over the network it would be remembered again at once, so
        // it is disconnected before it can be forgotten.
        compare(Android.actions(wifi), ["disconnect"]);
        const both = rowsOf(pixelOverUsb + "192.168.1.44:5555 device model:Pixel_10a\n", "", [pixel])[0];
        compare(Android.actions(both), ["disconnect"]);
        compare(Android.actions(rowsOf(pixelOverUsb, "", [pixel])[0]), ["forget", "connectWirelessly"]);
        compare(Android.actions(rowsOf("", wirelessDebuggingOn)[0]), ["connect"]);
        compare(Android.actions(rowsOf("", wirelessDebuggingOn, [pixel])[0]), ["connect", "forget"]);
        compare(Android.actions(rowsOf("", "", [pixel])[0]), ["connect", "forget"]);
    }

    // The panel runs an action by calling the service method its table
    // names, so each one has to be a method of services/AndroidDevices.qml.
    function test_everyActionHasALabelAndAServiceMethod() {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("../services/AndroidDevices.qml"), false);
        request.send(null);
        const service = request.responseText;
        compare(Object.keys(Android.rowActions), ["connect", "disconnect", "forget", "connectWirelessly"]);
        for (const action of Object.keys(Android.rowActions)) {
            const entry = Android.rowActions[action];
            verify(entry.label !== "", action);
            verify(new RegExp("\\bfunction " + entry.method + "\\(row\\)").test(service),
                action + " → " + entry.method);
        }
        compare(Android.rowActions.connectWirelessly.label, "Connect wirelessly");
    }

    // An ip:port connection nobody can place asks the phone for its serial.
    function test_onlyUnplacedIpPortConnectionsAskForTheirSerial() {
        const devices = Android.parseDevices(pixelOverUsb
            + "192.168.1.44:5555 device model:Pixel_10a\n"
            + "192.168.1.70:5555 device model:Pixel_10a\n"
            + "192.168.1.71:5555 device model:Tab\n"
            + "192.168.1.72:5555 offline\n"
            + "adb-61291JEA326957-AbCdEf._adb-tls-connect._tcp device model:Pixel_10a\n");
        compare(Android.unplacedTransports(devices, [pixel], { "192.168.1.71:5555": "TAB1" }),
            ["192.168.1.70:5555"]);
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

    // Until `getprop ro.serialno` answers, its ip:port stands in for the
    // serial; remembering it then would leave a second, "Not seen" row.
    function test_aConnectionWhoseSerialIsntKnownYetIsntRemembered() {
        const unplaced = rowsOf("192.168.1.70:5555 device model:Pixel_10a\n", "", [pixel]);
        compare(unplaced[0].serial, "192.168.1.70:5555");
        compare(Android.remembered([pixel], unplaced), [pixel]);
        compare(Android.remembered([], unplaced), []);
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
        compare(Android.connectOutcome("failed to authenticate to 192.168.1.44:37045\n"), "unpaired");
    }

    // Other adb versions word it differently; whatever names the network is
    // unreachable, whatever names authentication or pairing is unpaired.
    function test_adbsOtherWordingsAreRecognised() {
        compare(Android.connectOutcome("failed to connect to '192.168.1.44:5555': No route to host\n"),
            "unreachable");
        compare(Android.connectOutcome("failed to connect to 192.168.1.44:5555: Connection timed out\n"),
            "unreachable");
        compare(Android.connectOutcome("cannot connect to 192.168.1.44:5555: Network is unreachable\n"),
            "unreachable");
        compare(Android.connectOutcome("failed to connect to 192.168.1.44:37045: Authentication failed\n"),
            "unpaired");
        compare(Android.connectOutcome("192.168.1.44:37045: device unauthorized.\n"), "unpaired");
        compare(Android.connectOutcome("failed to connect: TLS handshake failed\n"), "unpaired");
    }

    // Saying nothing of why, it could be either.
    function test_anUnexplainedFailureIsUnknown() {
        compare(Android.connectOutcome("failed to connect to 192.168.1.44:5555\n"), "unknown");
        compare(Android.connectOutcome(""), "unknown");
    }

    function test_whatThePanelSaysWhenConnectFails() {
        compare(Android.connectProblem("unreachable"), "Turn on Wireless debugging on the phone");
        compare(Android.connectProblem("unpaired"), "Not paired with this computer: pair it below");
        compare(Android.connectProblem("unknown"),
            "Couldn't connect: turn on Wireless debugging on the phone, or pair it below if it isn't paired with this computer");
        compare(Android.connectProblem("connected"), "");
    }

    // After every address failed, not being paired says more than not
    // answering, and an unexplained failure more than either alone.
    function test_theWorstOfSeveralAttemptsIsReported() {
        compare(Android.worstOutcome(["unreachable", "unpaired"]), "unpaired");
        compare(Android.worstOutcome(["unpaired", "unreachable"]), "unpaired");
        compare(Android.worstOutcome(["unreachable", "unknown"]), "unknown");
        compare(Android.worstOutcome(["unpaired", "unknown"]), "unpaired");
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

    // What wifiIpCommand prints (`ip route get 1.1.1.1`, then every inet
    // address), captured from the Pixel 10a on Wi-Fi with mobile data on.
    readonly property string routeOverWlan0: "1.1.1.1 via 192.168.1.1 dev wlan0 table 1047 src 192.168.1.44 uid 2000 \n    cache \n"
    readonly property string mobileAddresses: [
        "1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000",
        "    inet 127.0.0.1/8 scope host lo",
        "       valid_lft forever preferred_lft forever",
        "15: rmnet1: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc mq state UNKNOWN group default qlen 1000",
        "    inet 10.112.145.102/32 scope global rmnet1",
        "       valid_lft forever preferred_lft forever",
        ""
    ].join("\n")
    readonly property string wlanAddress: [
        "47: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000",
        "    inet 192.168.1.44/24 brd 192.168.1.255 scope global dynamic wlan0",
        "       valid_lft 82236sec preferred_lft 82236sec",
        ""
    ].join("\n")

    function test_theAndroidDevicesAddressIsTheOneItsDefaultRouteLeavesFrom() {
        compare(Android.wifiIp(routeOverWlan0 + mobileAddresses + wlanAddress), "192.168.1.44");
        // Whatever the interface is called.
        compare(Android.wifiIp("1.1.1.1 via 10.0.0.1 dev wifi0 src 10.0.0.23 uid 2000\n" + mobileAddresses),
            "10.0.0.23");
    }

    function test_withoutARouteAnyWlanAddressIsTaken() {
        compare(Android.wifiIp("RTNETLINK answers: Network is unreachable\n" + mobileAddresses
            + wlanAddress.replace(/wlan0/g, "wlan1")), "192.168.1.44");
    }

    // A default route over mobile data can't reach this computer.
    function test_aRouteOverMobileDataIsntWifi() {
        compare(Android.wifiIp("1.1.1.1 dev rmnet1 table 1003 src 10.112.145.102 uid 2000\n"
            + mobileAddresses), "");
        compare(Android.wifiIp("1.1.1.1 dev rmnet1 table 1003 src 10.112.145.102 uid 2000\n"
            + mobileAddresses + wlanAddress), "192.168.1.44");
    }

    function test_noAddressAtAllIsNone() {
        compare(Android.wifiIp(""), "");
        compare(Android.wifiIp("RTNETLINK answers: Network is unreachable\n" + mobileAddresses), "");
    }
}
