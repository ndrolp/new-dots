import QtQuick
import QtTest
import "../components/panels/AudioOutputs.js" as AudioOutputs

// An audio output is named by its short nickname (the connected monitor, the
// headset model), not by the sound card's long description. Without a
// nickname it falls back to the description, then to the internal node name.
TestCase {
    name: "AudioOutputs"

    function output(fields) {
        return Object.assign({
            nickname: "",
            description: "",
            name: ""
        }, fields);
    }

    function test_anOutputIsNamedByItsNickname() {
        compare(AudioOutputs.label(output({
            nickname: "Q27G42XE",
            description: "Core Ultra 200V Series Processors HD Audio HDMI / DisplayPort 1 Output",
            name: "alsa_output.pci-0000_00_1f.3-platform-sof_sdw.HiFi__HDMI1__sink"
        })), "Q27G42XE");
    }

    function test_withoutANicknameTheDescriptionIsUsed() {
        compare(AudioOutputs.label(output({
            description: "G522 LIGHTSPEED - Wireless Mode Analog Stereo",
            name: "alsa_output.usb-Logitech_G522-00.analog-stereo"
        })), "G522 LIGHTSPEED - Wireless Mode Analog Stereo");
    }

    function test_withoutANicknameOrDescriptionTheNodeNameIsUsed() {
        compare(AudioOutputs.label(output({
            name: "alsa_output.usb-Logitech_G522-00.analog-stereo"
        })), "alsa_output.usb-Logitech_G522-00.analog-stereo");
    }

    function test_anOutputWithNoNamesAtAllHasAnEmptyLabel() {
        compare(AudioOutputs.label(output({})), "");
        compare(AudioOutputs.label(null), "");
    }

    // The port (PipeWire `device.profile.description`) is the secondary line
    // under the nickname, so outputs sharing a sound card stay distinguishable.
    function test_anOutputsPortIsItsProfileDescription() {
        compare(AudioOutputs.port(output({
            nickname: "Q27G42XE",
            properties: {
                "device.profile.description": "HDMI / DisplayPort 1 Output"
            }
        })), "HDMI / DisplayPort 1 Output");
    }

    function test_aPortThatRepeatsTheLabelIsHidden() {
        compare(AudioOutputs.port(output({
            nickname: "Headphones",
            description: "Core Ultra 200V Series Processors HD Audio Headphones",
            properties: {
                "device.profile.description": "Headphones"
            }
        })), "");
    }

    // Without a nickname the label is the description, so the port is hidden
    // when it repeats the description instead.
    function test_withoutANicknameAPortThatRepeatsTheDescriptionIsHidden() {
        compare(AudioOutputs.port(output({
            description: "Analog Stereo",
            properties: {
                "device.profile.description": "Analog Stereo"
            }
        })), "");
    }

    function test_withoutANicknameADifferentPortIsShown() {
        compare(AudioOutputs.port(output({
            description: "G522 LIGHTSPEED - Wireless Mode",
            properties: {
                "device.profile.description": "Analog Stereo"
            }
        })), "Analog Stereo");
    }

    function test_anOutputWithoutAPortHasAnEmptyPort() {
        compare(AudioOutputs.port(output({
            nickname: "Q27G42XE"
        })), "");
        compare(AudioOutputs.port(output({
            nickname: "Q27G42XE",
            properties: {}
        })), "");
        compare(AudioOutputs.port(null), "");
    }
}
