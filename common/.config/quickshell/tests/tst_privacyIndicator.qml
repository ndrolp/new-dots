import QtQuick
import QtTest
import "../components/bar/PrivacyIndicator.js" as PrivacyIndicator

// The privacy indicator: which apps use the microphone or a camera, read
// from PipeWire.
TestCase {
    name: "PrivacyIndicator"

    // PipeWire nodes and links as plain objects, shaped like the ones the bar
    // reads from Quickshell's Pipewire service (the properties as pw-dump
    // shows them).
    readonly property var mic: ({
        id: 67,
        isStream: false,
        properties: { "media.class": "Audio/Source", "device.api": "alsa",
            "node.name": "alsa_input.pci-0000_00_1f.3-platform-sof_sdw.HiFi__Mic__source" }
    })
    readonly property var discordStream: ({
        id: 140,
        isStream: true,
        properties: { "media.class": "Stream/Input/Audio", "application.name": "Discord",
            "application.process.binary": "Discord", "node.name": "Discord" }
    })

    function test_anAppRecordingFromAMicrophoneUsesIt() {
        compare(PrivacyIndicator.captures([mic, discordStream], [{ source: 67, target: 140 }]),
            { microphone: ["Discord"], camera: [] });
    }

    readonly property var speakers: ({
        id: 64,
        isStream: false,
        properties: { "media.class": "Audio/Sink", "device.api": "alsa",
            "node.name": "alsa_output.pci-0000_00_1f.3-platform-sof_sdw.HiFi__HDMI1__sink" }
    })
    // The shell's cava, as pw-dump shows it: it listens to the output.
    readonly property var cavaStream: ({
        id: 113,
        isStream: true,
        properties: { "media.class": "Stream/Input/Audio", "media.name": "cava", "node.name": "cava",
            "media.category": "Capture", "stream.capture.sink": true }
    })
    // A level meter reading the microphone (pavucontrol's, or the shell's
    // own): a monitoring stream, not a recording.
    readonly property var meterStream: ({
        id: 150,
        isStream: true,
        properties: { "media.class": "Stream/Input/Audio", "application.name": "quickshell",
            "application.process.binary": "quickshell", "stream.monitor": true }
    })
    readonly property var shellStream: ({
        id: 151,
        isStream: true,
        properties: { "media.class": "Stream/Input/Audio", "application.process.binary": "quickshell" }
    })

    // The shell's own audio level monitoring doesn't count as using the
    // microphone: cava listens to the output, and a level meter only
    // monitors.
    function test_theShellsOwnLevelMonitoringDoesNotUseTheMicrophone_data() {
        return [
            { tag: "cava on the output", nodes: [speakers, cavaStream], link: { source: 64, target: 113 } },
            { tag: "cava on the microphone", nodes: [mic, cavaStream], link: { source: 67, target: 113 } },
            { tag: "a level meter", nodes: [mic, meterStream], link: { source: 67, target: 150 } },
            { tag: "the shell itself", nodes: [mic, shellStream], link: { source: 67, target: 151 } }
        ];
    }

    function test_theShellsOwnLevelMonitoringDoesNotUseTheMicrophone(data) {
        compare(PrivacyIndicator.captures(data.nodes, [data.link]), { microphone: [], camera: [] });
    }

    // PipeWire hands its properties over as strings: cava's
    // stream.capture.sink and a level meter's stream.monitor read "true".
    function test_monitoringFlagsGivenAsStringsDoNotUseTheMicrophone_data() {
        return [
            { tag: "cava", property: "stream.capture.sink" },
            { tag: "a level meter", property: "stream.monitor" }
        ];
    }

    function test_monitoringFlagsGivenAsStringsDoNotUseTheMicrophone(data) {
        const properties = { "media.class": "Stream/Input/Audio", "application.name": "pavucontrol",
            "application.process.binary": "pavucontrol" };
        properties[data.property] = "true";
        const stream = { id: 170, isStream: true, properties: properties };

        compare(PrivacyIndicator.captures([mic, stream], [{ source: 67, target: 170 }]),
            { microphone: [], camera: [] });
    }

    // A flag PipeWire sets to "false" doesn't make a recording a monitor.
    function test_aMonitoringFlagSetToFalseStillRecords() {
        const properties = { "media.class": "Stream/Input/Audio", "application.name": "Discord",
            "stream.monitor": "false" };

        compare(PrivacyIndicator.captures([mic, { id: 171, isStream: true, properties: properties }],
            [{ source: 67, target: 171 }]), { microphone: ["Discord"], camera: [] });
    }

    readonly property var camera: ({
        id: 97,
        isStream: false,
        properties: { "media.class": "Video/Source", "media.role": "Camera", "device.api": "v4l2",
            "node.name": "v4l2_input.pci-0000_00_14.0-usb-0_4_1.0" }
    })
    readonly property var portalScreen: ({
        id: 101,
        isStream: false,
        properties: { "media.class": "Video/Source", "node.name": "xdph-streaming-0",
            "application.name": "xdg-desktop-portal-hyprland" }
    })
    readonly property var firefoxVideo: ({
        id: 120,
        isStream: true,
        properties: { "media.class": "Stream/Input/Video", "application.name": "Firefox",
            "application.process.binary": "firefox" }
    })
    readonly property var firefoxAudio: ({
        id: 121,
        isStream: true,
        properties: { "media.class": "Stream/Input/Audio", "application.name": "Firefox",
            "application.process.binary": "firefox" }
    })

    function test_anAppReadingACameraUsesIt() {
        compare(PrivacyIndicator.captures([camera, firefoxVideo], [{ source: 97, target: 120 }]),
            { microphone: [], camera: ["Firefox"] });
    }

    // Sharing the screen is the recording indicator's.
    function test_aScreenShareIsNotACamera() {
        compare(PrivacyIndicator.captures([portalScreen, firefoxVideo], [{ source: 101, target: 120 }]),
            { microphone: [], camera: [] });
    }

    // A call uses both; each app is named once per kind, however many
    // streams it has.
    function test_aCallUsesTheMicrophoneAndTheCamera() {
        const secondTab = { id: 122, isStream: true, properties: firefoxAudio.properties };

        compare(PrivacyIndicator.captures([mic, camera, firefoxVideo, firefoxAudio, secondTab, discordStream],
            [{ source: 97, target: 120 }, { source: 67, target: 121 }, { source: 67, target: 122 },
                { source: 67, target: 140 }]),
            { microphone: ["Firefox", "Discord"], camera: ["Firefox"] });
    }

    // A stream that isn't linked to a device yet uses nothing.
    function test_anUnlinkedStreamUsesNothing() {
        compare(PrivacyIndicator.captures([mic, camera, firefoxVideo, discordStream], []),
            { microphone: [], camera: [] });
    }

    // A noise filter's own capture of the microphone (a loopback or filter
    // chain, which PipeWire groups by node.link-group) isn't an app; an app
    // recording from the filter's virtual source is.
    function test_aFiltersOwnCaptureIsNotAnApp() {
        const filterCapture = { id: 160, isStream: true, properties: { "media.class": "Stream/Input/Audio",
            "node.name": "input.filter-chain-noise", "node.link-group": "filter-chain-1234-20" } };
        const filteredMic = { id: 161, isStream: false, properties: { "media.class": "Audio/Source",
            "node.name": "effect_output.noise", "node.link-group": "filter-chain-1234-20" } };

        compare(PrivacyIndicator.captures([mic, filterCapture, filteredMic, discordStream],
            [{ source: 67, target: 160 }, { source: 161, target: 140 }]),
            { microphone: ["Discord"], camera: [] });
    }

    // An app without a name is named after its binary, else its node.
    function test_anAppWithoutANameIsNamedAfterItsBinaryOrNode() {
        const obs = { id: 130, isStream: true, properties: { "media.class": "Stream/Input/Video",
            "application.process.binary": "obs" } };
        const unnamed = { id: 131, isStream: true, properties: { "media.class": "Stream/Input/Audio",
            "node.name": "ALSA plug-in [arecord]" } };

        compare(PrivacyIndicator.captures([mic, camera, obs, unnamed],
            [{ source: 97, target: 130 }, { source: 67, target: 131 }]),
            { microphone: ["ALSA plug-in [arecord]"], camera: ["obs"] });
    }

    // The element shows the mic icon, the camera icon or both, and nothing
    // while nothing is captured.
    function test_theElementShowsAnIconPerDeviceKindInUse_data() {
        return [
            { tag: "microphone", captures: { microphone: ["Discord"], camera: [] }, icons: ["󰍬"] },
            { tag: "camera", captures: { microphone: [], camera: ["obs"] }, icons: ["󰕧"] },
            { tag: "both", captures: { microphone: ["Firefox"], camera: ["Firefox"] }, icons: ["󰍬", "󰕧"] },
            { tag: "nothing", captures: { microphone: [], camera: [] }, icons: [] }
        ];
    }

    function test_theElementShowsAnIconPerDeviceKindInUse(data) {
        compare(PrivacyIndicator.icons(data.captures), data.icons);
    }

    // Its popup lists the apps under each device kind in use.
    function test_thePopupListsTheAppsPerDeviceKind() {
        compare(PrivacyIndicator.sections({ microphone: ["Firefox", "Discord"], camera: ["Firefox"] }), [
            { kind: "microphone", title: "Microphone", icon: "󰍬", apps: ["Firefox", "Discord"] },
            { kind: "camera", title: "Camera", icon: "󰕧", apps: ["Firefox"] }
        ]);
        compare(PrivacyIndicator.sections({ microphone: [], camera: ["obs"] }), [
            { kind: "camera", title: "Camera", icon: "󰕧", apps: ["obs"] }
        ]);
    }

    // An app PipeWire gives no name at all is still listed.
    function test_anAppWithNoNameAtAllIsListedAsAnApp() {
        compare(PrivacyIndicator.sections({ microphone: [""], camera: [] })[0].apps, ["An app"]);
    }
}
