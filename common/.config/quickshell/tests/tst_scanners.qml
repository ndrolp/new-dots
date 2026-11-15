import QtQuick
import QtTest
import "../services/Scanners.js" as Scanners

// The scanners in the Printers panel, read from what
// `scanimage -f "%d<TAB>%v<TAB>%m<TAB>%t%n"` prints (sane-backends 1.4),
// how a scan is named and run, and the scan settings kept in appearance.json.
TestCase {
    name: "Scanners"

    function line(device, vendor, model, type) {
        return [device, vendor, model, type].join("\t");
    }

    function test_noScannersListsNone() {
        compare(Scanners.parse(""), []);
    }

    // The laptop's webcams show up through the v4l backend; they aren't scanners.
    function test_webcamsAreNotScanners() {
        compare(Scanners.parse([
            line("v4l:/dev/video2", "Noname", "Integrated Camera: Integrated I", "virtual device"),
            line("v4l:/dev/video0", "Noname", "Integrated Camera: Integrated C", "virtual device"),
            ""
        ].join("\n")), []);
    }

    function test_networkAndUsbScannersAreListedByName() {
        compare(Scanners.parse([
            line("airscan:e0:Canon TS5300 series", "Canon", "TS5300 series", "eSCL network scanner"),
            line("v4l:/dev/video0", "Noname", "Integrated Camera", "virtual device"),
            line("epkowa:interpreter:001:004", "Epson", "Perfection V39", "flatbed scanner"),
            ""
        ].join("\n")), [{
            device: "airscan:e0:Canon TS5300 series",
            name: "Canon TS5300 series",
            connection: "network"
        }, {
            device: "epkowa:interpreter:001:004",
            name: "Epson Perfection V39",
            connection: "usb"
        }]);
    }

    function connectionOf(device) {
        return Scanners.parse(line(device, "Vendor", "Model", "flatbed scanner") + "\n")[0].connection;
    }

    function test_backendsWithANetworkAddressAreNetwork() {
        for (const device of ["escl:https://192.168.1.5:443", "net:server.local:pixma:MX920",
                "epson2:net:192.168.1.30", "hpaio:/net/officejet_8010?ip=10.0.0.5"])
            compare(connectionOf(device), "network", device);
        for (const device of ["pixma:04A91912_43B2C1", "hpaio:/usb/Deskjet_2700?serial=CN1", "genesys:libusb:001:007"])
            compare(connectionOf(device), "usb", device);
    }

    // The agreed name: ~/Pictures/Scans/scan-YYYY-MM-DD-HHMMSS.<ext>, in local time.
    function test_aScanIsNamedAfterWhenItStarted() {
        const date = new Date(2026, 10, 5, 9, 3, 7);
        compare(Scanners.fileName(date, "pdf"), "scan-2026-11-05-090307.pdf");
        compare(Scanners.fileName(date, "png"), "scan-2026-11-05-090307.png");
        compare(Scanners.filePath("/home/me", date, "pdf"), "/home/me/Pictures/Scans/scan-2026-11-05-090307.pdf");
        compare(Scanners.folder("/home/me"), "/home/me/Pictures/Scans");
    }

    // Before any scan, and for anything appearance.json holds that isn't a choice.
    function test_scanSettingsStartAt300DpiColourPdf() {
        const defaults = { resolution: 300, mode: "color", format: "pdf" };
        compare(Scanners.settings(undefined), defaults);
        compare(Scanners.settings({}), defaults);
        compare(Scanners.settings({ resolution: 1200, mode: "sepia", format: "tiff" }), defaults);
    }

    function test_theLastSettingsUsedAreKept() {
        compare(Scanners.settings({ resolution: 600, mode: "lineart", format: "png" }),
            { resolution: 600, mode: "lineart", format: "png" });
        compare(Scanners.settings({ resolution: 150, mode: "gray" }),
            { resolution: 150, mode: "gray", format: "pdf" });
    }

    // scanimage -p prints progress on stderr; the folder is made first.
    function test_aScanRunsScanimageWithTheSettingsIntoTheFile() {
        const path = "/home/me/Pictures/Scans/scan-2026-11-05-090307.pdf";
        const command = Scanners.scanCommand("airscan:e0:Canon TS5300 series",
            { resolution: 150, mode: "gray", format: "pdf" }, path);
        compare(command.slice(0, 2), ["sh", "-c"]);
        compare(command.slice(3), ["sh", "/home/me/Pictures/Scans", path,
            "scanimage", "-d", "airscan:e0:Canon TS5300 series", "--resolution", "150",
            "--mode", "Gray", "--format=pdf", "-p", "-o", path]);
    }

    function test_eachColourModeIsTheModeSaneNames() {
        const modes = { color: "Color", gray: "Gray", lineart: "Lineart" };
        for (const mode in modes) {
            const command = Scanners.scanCommand("pixma:1", { resolution: 300, mode: mode, format: "png" }, "/s.png");
            compare(command[command.indexOf("--mode") + 1], modes[mode], mode);
            verify(command.indexOf("--format=png") > 0);
        }
    }

    // scanimage rewrites "Progress: N%" on one line with carriage returns.
    function test_progressIsTheLastPercentageScanimagePrinted() {
        compare(Scanners.progressOf(""), 0);
        compare(Scanners.progressOf("Progress: 0.0%\rProgress: 12.5%\r"), 0.125);
        compare(Scanners.progressOf("Progress: 40.0%\rProgress: 100.0%\r"), 1);
    }

    function test_aFailedScanSaysWhatScanimageSaid() {
        compare(Scanners.failureOf(
            "Progress: 3.2%\rscanimage: sane_start: Document feeder out of documents\n"),
            "Document feeder out of documents");
        compare(Scanners.failureOf(
            "scanimage: open of device airscan:e0:Canon failed: Invalid argument\n"),
            "open of device airscan:e0:Canon failed: Invalid argument");
        compare(Scanners.failureOf(""), "The scan failed");
    }
}
