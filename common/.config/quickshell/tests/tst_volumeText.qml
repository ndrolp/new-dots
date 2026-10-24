import QtQuick
import QtTest
import "../components/bar/VolumeText.js" as VolumeText

// With the volume meter off, the audio bar element shows the volume as a
// whole-number percentage. Volumes over 100% are shown as they are.
TestCase {
    name: "VolumeText"

    function test_wholePercentage() {
        compare(VolumeText.percentage(0.45), "45%");
    }

    function test_roundsToWholeNumber() {
        compare(VolumeText.percentage(0.456), "46%");
        compare(VolumeText.percentage(0.454), "45%");
    }

    function test_silentAndFull() {
        compare(VolumeText.percentage(0), "0%");
        compare(VolumeText.percentage(1), "100%");
    }

    function test_overAmplifiedShownAsIs() {
        compare(VolumeText.percentage(1.2), "120%");
    }
}
