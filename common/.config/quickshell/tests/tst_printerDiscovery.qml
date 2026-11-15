import QtQuick
import QtTest
import "../services/PrinterDiscovery.js" as Discovery

// The discovered printers in the Printers panel, read from what
// `avahi-browse -rpk _ipp._tcp` (and `_ipps._tcp`) streams while the panel
// is open, without the ones already added, and the command that adds one.
TestCase {
    name: "PrinterDiscovery"

    readonly property string laserOnWifi: "=;wlan0;IPv4;HP\\032LaserJet\\032Pro\\032M404\\032\\091A1B2C3\\093;_ipp._tcp;local;"
        + "HPA1B2C3.local;192.168.1.20;631;\"txtvers=1\" \"ty=HP LaserJet Pro M404\" \"rp=ipp/print\" "
        + "\"pdl=application/octet-stream,image/urf,image/pwg-raster\" \"UUID=564e4333-4b30-3230-3538-a1b2c3d4e5f6\""

    function found(lines) {
        let services = {};
        for (const line of lines)
            services = Discovery.takeLine(services, line);
        return services;
    }

    function test_aResolvedNetworkPrinterIsDiscovered() {
        compare(Discovery.discovered(found([laserOnWifi]), []), [{
            key: "564e4333-4b30-3230-3538-a1b2c3d4e5f6",
            model: "HP LaserJet Pro M404",
            service: "HP LaserJet Pro M404 [A1B2C3]",
            connection: "network",
            uri: "dnssd://HP%20LaserJet%20Pro%20M404%20%5BA1B2C3%5D._ipp._tcp.local/?uuid=564e4333-4b30-3230-3538-a1b2c3d4e5f6",
            driverless: true
        }]);
    }

    function test_aPrinterThatGoesAwayIsNoLongerDiscovered() {
        compare(Discovery.discovered(found([
            "+;wlan0;IPv4;HP\\032LaserJet\\032Pro\\032M404\\032\\091A1B2C3\\093;_ipp._tcp;local",
            laserOnWifi,
            "-;wlan0;IPv4;HP\\032LaserJet\\032Pro\\032M404\\032\\091A1B2C3\\093;_ipp._tcp;local"
        ]), []), []);
    }

    // The same printer over IPv6, over IPPS and on a second interface.
    function test_aPrinterSeenSeveralWaysIsDiscoveredOnce() {
        const printers = Discovery.discovered(found([
            laserOnWifi.replace("IPv4", "IPv6").replace("192.168.1.20", "fe80::1"),
            laserOnWifi.replace("_ipp._tcp", "_ipps._tcp"),
            laserOnWifi.replace("wlan0", "eth0"),
            laserOnWifi
        ]), []);
        compare(printers.length, 1);
        verify(printers[0].uri.indexOf("._ipp._tcp.local/") > 0, printers[0].uri);
    }

    // One the network only sees over IPPS keeps it.
    function test_aPrinterOnlyOverIppsIsAddedOverIpps() {
        const printers = Discovery.discovered(found([laserOnWifi.replace("_ipp._tcp", "_ipps._tcp")]), []);
        verify(printers[0].uri.indexOf("._ipps._tcp.local/") > 0, printers[0].uri);
    }

    // ipp-usb serves a USB printer as IPP on localhost, advertised on lo.
    readonly property string inkjetOverUsb: "=;lo;IPv4;EPSON\\032ET-2850\\032Series\\032\\040USB\\041;_ipp._tcp;local;"
        + "myhost.local;127.0.0.1;60000;\"ty=EPSON ET-2850 Series\" \"rp=ipp/print\" \"pdl=image/urf,image/pwg-raster\" "
        + "\"UUID=cfe92100-67c4-11d4-a45f-e0bb9e1d2a3b\""

    function test_aUsbPrinterIsDiscoveredAsUsb() {
        compare(Discovery.discovered(found([inkjetOverUsb]), []), [{
            key: "cfe92100-67c4-11d4-a45f-e0bb9e1d2a3b",
            model: "EPSON ET-2850 Series",
            service: "EPSON ET-2850 Series (USB)",
            connection: "usb",
            uri: "ipp://localhost:60000/ipp/print",
            driverless: true
        }]);
    }

    // This computer's own CUPS advertises its shared printers on lo too.
    function test_thisComputersOwnQueuesAreNotDiscovered() {
        compare(Discovery.discovered(found([
            "=;lo;IPv4;Office_Laser\\032\\064\\032myhost;_ipp._tcp;local;myhost.local;127.0.0.1;631;"
                + "\"txtvers=1\" \"rp=printers/Office_Laser\" \"ty=HP LaserJet Pro M404\" \"printer-type=0x809046\""
        ]), []), []);
    }

    // However it was added: from here, by CUPS's web page or
    // system-config-printer, by its address or its name on the network.
    function test_aPrinterAlreadyAddedIsNotDiscovered() {
        const services = found([laserOnWifi, laserOnWifi.replace("IPv4", "IPv6").replace("192.168.1.20", "fe80::1"),
            inkjetOverUsb]);
        for (const uri of [
                "dnssd://HP%20LaserJet%20Pro%20M404%20%5BA1B2C3%5D._ipp._tcp.local/?uuid=564e4333-4b30-3230-3538-a1b2c3d4e5f6",
                "dnssd://HP%20LaserJet%20Pro%20M404%20%5BA1B2C3%5D._ipps._tcp.local/",
                "ipp://HPA1B2C3.local:631/ipp/print",
                "ipps://hpa1b2c3.local/ipp/print",
                "ipp://192.168.1.20/ipp/print",
                "socket://192.168.1.20:9100",
                "ipp://[fe80::1]:631/ipp/print",
                "implicitclass://Something/?uuid=564E4333-4B30-3230-3538-A1B2C3D4E5F6"]) {
            const models = Discovery.discovered(services, [uri]).map(printer => printer.model);
            compare(models, ["EPSON ET-2850 Series"], uri);
        }
        compare(Discovery.discovered(services, ["ipp://localhost:60000/ipp/print"]).map(printer => printer.model),
            ["HP LaserJet Pro M404"]);
    }

    function test_otherPrintersDontHideADiscoveredOne() {
        const services = found([laserOnWifi, inkjetOverUsb]);
        compare(Discovery.discovered(services, [
            "ipp://192.168.1.21/ipp/print", "ipp://localhost:60001/ipp/print", "usb://HP/LaserJet%20Pro%20M404",
            "dnssd://HP%20LaserJet%20Pro%20M404%20%5BOTHER%5D._ipp._tcp.local/", "ipp://otherhost.local/ipp/print"
        ]).length, 2);
    }

    // What `lpstat -v` prints under LC_ALL=C.
    function test_theAddedPrintersUrisAreReadFromLpstat() {
        compare(Discovery.addedUris([
            "device for Office_Laser: ipp://HPA1B2C3.local:631/ipp/print",
            "device for Epson: ipp://localhost:60000/ipp/print",
            ""
        ].join("\n")), ["ipp://HPA1B2C3.local:631/ipp/print", "ipp://localhost:60000/ipp/print"]);
        compare(Discovery.addedUris(""), []);
    }

    // Driverless (IPP Everywhere), named after the model, no password: the
    // user is in wheel.
    function test_addingAPrinterNamesItAfterTheModel() {
        const laser = Discovery.discovered(found([laserOnWifi]), [])[0];
        compare(Discovery.addCommand(laser, []), ["lpadmin", "-p", "HP_LaserJet_Pro_M404", "-E", "-v",
            "dnssd://HP%20LaserJet%20Pro%20M404%20%5BA1B2C3%5D._ipp._tcp.local/?uuid=564e4333-4b30-3230-3538-a1b2c3d4e5f6",
            "-m", "everywhere"]);
    }

    function test_aSecondPrinterOfTheSameModelGetsANumber() {
        const laser = Discovery.discovered(found([laserOnWifi]), [])[0];
        compare(Discovery.addCommand(laser, ["hp_laserjet_pro_m404", "HP_LaserJet_Pro_M404_2"])[2],
            "HP_LaserJet_Pro_M404_3");
    }

    function test_aModelNameCupsWouldRefuseIsMadeSafe() {
        compare(Discovery.queueName("Brother HL-L2350DW series (USB) #2 / ünï", []), "Brother_HL-L2350DW_series_USB_2_n");
        compare(Discovery.queueName("   ", []), "Printer");
    }

    function test_whyNetworkPrintersCantBeFound() {
        compare(Discovery.browseProblem("Failed to create client object: Daemon not running\n"),
            "avahi-daemon isn't running, so printers on the network and USB can't be found. "
            + "Start it with: systemctl enable --now avahi-daemon");
        compare(Discovery.browseProblem("Failed to create browser for _ipp._tcp: Access denied\n"),
            "Can't look for printers: Failed to create browser for _ipp._tcp: Access denied");
        compare(Discovery.browseProblem("Failed to resolve service 'X' of type '_ipp._tcp' in domain 'local': Timeout reached\n"), "");
        compare(Discovery.browseProblem(""), "");
    }

    function test_whyAddingAPrinterFailed() {
        compare(Discovery.addProblem("lpadmin: Unable to query printer: Bad Request\n", "HP LaserJet Pro M404"),
            "Couldn't add HP LaserJet Pro M404 driverless: Unable to query printer: Bad Request");
        compare(Discovery.addProblem("", "HP LaserJet Pro M404"), "Couldn't add HP LaserJet Pro M404 driverless");
    }

    function test_aPrinterWithoutDriverlessFormatsCantBeAddedDriverless() {
        const printers = Discovery.discovered(found([
            laserOnWifi.replace("application/octet-stream,image/urf,image/pwg-raster", "application/postscript,application/vnd.hp-PCL")
        ]), []);
        compare(printers[0].driverless, false);
    }
}
