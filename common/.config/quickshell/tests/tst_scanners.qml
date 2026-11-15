import QtQuick
import QtTest
import "../services/Scanners.js" as Scanners

// The scanners in the Printers panel, read from what
// `scanimage -f "%d<TAB>%v<TAB>%m<TAB>%t%n"` prints (sane-backends 1.4),
// how a scan is named and run, and the scan settings kept in appearance.json.
TestCase {
    name: "Scanners"

    function line(saneName, vendor, model, type) {
        return [saneName, vendor, model, type].join("\t");
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
            saneName: "airscan:e0:Canon TS5300 series",
            name: "Canon TS5300 series",
            connection: "network"
        }, {
            saneName: "epkowa:interpreter:001:004",
            name: "Epson Perfection V39",
            connection: "usb"
        }]);
    }

    function connectionOf(saneName) {
        return Scanners.parse(line(saneName, "Vendor", "Model", "flatbed scanner") + "\n")[0].connection;
    }

    function test_backendsWithANetworkAddressAreNetwork() {
        for (const saneName of ["escl:https://192.168.1.5:443", "net:server.local:pixma:MX920",
                "epson2:net:192.168.1.30", "hpaio:/net/officejet_8010?ip=10.0.0.5"])
            compare(connectionOf(saneName), "network", saneName);
        for (const saneName of ["pixma:04A91912_43B2C1", "hpaio:/usb/Deskjet_2700?serial=CN1", "genesys:libusb:001:007"])
            compare(connectionOf(saneName), "usb", saneName);
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

    // scanimage -p prints progress on stderr; scan.sh makes the folder first
    // and tells whether the file was saved (tests/scan.sh).
    function test_aScanRunsScanimageWithTheSettingsIntoTheFile() {
        const path = "/home/me/Pictures/Scans/scan-2026-11-05-090307.pdf";
        compare(Scanners.scanCommand("/qs/services/scan.sh", "airscan:e0:Canon TS5300 series",
            { resolution: 150, mode: "gray", format: "pdf" }, path),
            ["bash", "/qs/services/scan.sh", path,
            "scanimage", "-d", "airscan:e0:Canon TS5300 series", "--resolution", "150",
            "--mode", "Gray", "--format=pdf", "-p", "-o", path]);
    }

    // What `scanimage -d <scanner> -A` prints, with `modeLine` as its --mode option.
    function options(modeLine) {
        return [
            "",
            "All options specific to device `pixma:04A91912':",
            "  Scan mode:",
            "    --resolution 75|150|300|600dpi [300]",
            "        Sets the resolution of the scanned image.",
            modeLine,
            "        Selects the scan mode (e.g., lineart, monochrome, or color).",
            "    --source Flatbed [Flatbed]",
            ""
        ].join("\n");
    }

    function test_theModesAScannerOffersAreReadFromItsOptions() {
        compare(Scanners.parseModes(options("    --mode Lineart|Gray|Color [Color]")), ["Lineart", "Gray", "Color"]);
        compare(Scanners.parseModes(options("    --mode Color|Gray [Color]")), ["Color", "Gray"]);
        compare(Scanners.parseModes(options("    --mode Black & White|Gray[Error Diffusion]|True Gray|24bit Color [24bit Color]")),
            ["Black & White", "Gray[Error Diffusion]", "True Gray", "24bit Color"]);
        compare(Scanners.parseModes(options("    --mode Binary|Gray|Color [inactive]")), ["Binary", "Gray", "Color"]);
        compare(Scanners.parseModes(""), []);
    }

    function values(modes) {
        return modes.map(mode => mode.value + "=" + mode.sane);
    }

    // The colour choices are only the ones the scanner offers, each scanned
    // with the scanner's own name for it.
    function test_onlyTheColourModesAScannerOffersAreChoices() {
        compare(values(Scanners.availableModes(["Lineart", "Gray", "Color"])),
            ["color=Color", "gray=Gray", "lineart=Lineart"]);
        compare(values(Scanners.availableModes(["Color", "Gray"])), ["color=Color", "gray=Gray"]);
        compare(values(Scanners.availableModes(["Binary", "Gray", "Color"])),
            ["color=Color", "gray=Gray", "lineart=Binary"]);
        compare(values(Scanners.availableModes(["Lineart", "Halftone", "Gray", "Color"])),
            ["color=Color", "gray=Gray", "lineart=Lineart"]);
        compare(values(Scanners.availableModes(["Black & White", "Gray[Error Diffusion]", "True Gray",
            "24bit Color[Fast]", "24bit Color"])),
            ["color=24bit Color", "gray=True Gray", "lineart=Black & White"]);
        compare(Scanners.availableModes(["Black & White"])[0].label, "Black and white");
    }

    // Before the modes are read, or when they can't be, all three are offered.
    function test_aScannerWhoseModesArentKnownOffersAllThree() {
        compare(values(Scanners.availableModes([])), ["color=Color", "gray=Gray", "lineart=Lineart"]);
        compare(values(Scanners.availableModes(["auto"])), ["color=Color", "gray=Gray", "lineart=Lineart"]);
    }

    // A remembered mode the scanner doesn't offer falls back to the nearest
    // one it does: black and white to greyscale, greyscale to colour.
    function test_aModeTheScannerDoesntOfferFallsBackToTheNearest() {
        const colourAndGrey = Scanners.availableModes(["Color", "Gray"]);
        compare(Scanners.modeFor("lineart", colourAndGrey), "gray");
        compare(Scanners.modeFor("gray", colourAndGrey), "gray");
        compare(Scanners.modeFor("gray", Scanners.availableModes(["Color", "Lineart"])), "color");
        compare(Scanners.modeFor("color", Scanners.availableModes(["Lineart"])), "lineart");
        compare(Scanners.modeFor("color", Scanners.availableModes(["Gray", "Lineart"])), "gray");
    }

    function test_aScanUsesTheScannersNameForTheMode() {
        const brother = Scanners.availableModes(["Black & White", "True Gray", "24bit Color"]);
        const command = Scanners.scanCommand("/scan.sh", "brother4:net1;dev0",
            { resolution: 300, mode: "lineart", format: "png" }, "/s.png", brother);
        compare(command[command.indexOf("--mode") + 1], "Black & White");
        verify(command.indexOf("--format=png") > 0);
        const airscan = Scanners.scanCommand("/scan.sh", "airscan:e0:Canon",
            { resolution: 300, mode: "lineart", format: "pdf" }, "/s.pdf", Scanners.availableModes(["Color", "Gray"]));
        compare(airscan[airscan.indexOf("--mode") + 1], "Gray");
    }

    function test_theModesAreReadInEnglish() {
        compare(Scanners.modesCommand("airscan:e0:Canon TS5300 series"),
            ["env", "LC_ALL=C", "scanimage", "-d", "airscan:e0:Canon TS5300 series", "-A"]);
    }

    // *Show in folder* hands the file manager a file:// URI, encoded (a
    // quote too, so it can't end the D-Bus array's string early), as an
    // argument of its own, not spliced into the call's text by the shell.
    function test_theSavedNoticeShowsTheFileByItsEncodedUri() {
        const path = "/home/me/Pictures/Scans/it's 100% #1.pdf";
        compare(Scanners.fileUri(path), "file:///home/me/Pictures/Scans/it%27s%20100%25%20%231.pdf");
        const command = Scanners.savedNoticeCommand(path);
        compare(command.slice(-2), [path, "['file:///home/me/Pictures/Scans/it%27s%20100%25%20%231.pdf']"]);
        verify(command[2].indexOf("file://") < 0, "the URI is built in the shell");
        verify(command[2].indexOf('"$2"') >= 0, "the URI isn't passed on");
    }

    // scan.sh exits 0 when the file was saved, 100 when it was saved but
    // scanimage failed after, and anything else when nothing was saved.
    function test_aScanIsSavedWhenItsFileIsThere() {
        compare(Scanners.outcomeOf(0, "Progress: 100.0%\r"), { saved: true, problem: "" });
        compare(Scanners.outcomeOf(100, "Progress: 100.0%\rscanimage: sane_cancel: Device busy\n"),
            { saved: true, problem: "Device busy" });
        compare(Scanners.outcomeOf(1, "scanimage: sane_start: Document feeder out of documents\n"),
            { saved: false, problem: "Document feeder out of documents" });
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
