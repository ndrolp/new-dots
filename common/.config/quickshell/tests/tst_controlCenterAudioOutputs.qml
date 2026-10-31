import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config/Motion.js" as Motion

// The control center's audio output subpage: the audio outputs, the one
// sound plays through marked, and a back arrow. Choosing an output asks the
// host to switch to it; the subpage stays. Pointer events don't reach items
// under qmltestrunner offscreen, so rows and the back arrow are driven
// through what their taps call.
TestCase {
    name: "ControlCenterAudioOutputs"
    width: 500
    height: 500
    visible: true
    when: windowShown

    QtObject {
        id: barAppearance

        property int radius: 12
        property int textSize: 13
        readonly property var motion: Motion.motion(true)
    }

    QtObject {
        id: speakers

        property string nickname: "Speakers"
        property string description: "Analog Stereo"
        property string name: "alsa_output.speakers"
        property var properties: ({})
    }

    QtObject {
        id: monitor

        property string nickname: "Q27G42XE"
        property string description: "HDMI / DisplayPort 1 Output"
        property string name: "alsa_output.hdmi"
        property var properties: ({})
    }

    Component {
        id: pageComponent

        Panels.ControlCenterAudioOutputs {
            appearance: barAppearance
            width: 400
        }
    }

    SignalSpy {
        id: chosenSpy

        signalName: "outputChosen"
    }

    SignalSpy {
        id: backSpy

        signalName: "backRequested"
    }

    function makePage(properties) {
        const page = createTemporaryObject(pageComponent, this, properties || {});
        verify(page);
        chosenSpy.clear();
        chosenSpy.target = page;
        backSpy.clear();
        backSpy.target = page;
        return page;
    }

    function rows(page) {
        const found = [];
        const column = findChild(page, "audioOutputList");
        verify(column);
        for (let index = 0; index < column.children.length; index++) {
            const child = column.children[index];
            if (child.objectName === "audioOutputRow")
                found.push(child);
        }
        return found;
    }

    function test_itListsEveryOutputAndMarksTheOneSoundPlaysThrough() {
        const page = makePage({ outputs: [speakers, monitor], current: monitor });
        const shown = rows(page);

        compare(shown.length, 2);
        compare(shown[0].output, speakers);
        compare(shown[0].active, false);
        compare(shown[1].output, monitor);
        compare(shown[1].active, true);
    }

    function test_choosingAnOutputAsksToSwitchToIt() {
        const page = makePage({ outputs: [speakers, monitor], current: speakers });

        rows(page)[1].choose();
        compare(chosenSpy.count, 1);
        compare(chosenSpy.signalArguments[0][0], monitor);
        compare(backSpy.count, 0);
    }

    function test_theBackArrowAsksToGoBack() {
        const page = makePage({ outputs: [speakers], current: speakers });
        const arrow = findChild(page, "backArrow");
        verify(arrow);

        arrow.activated();
        compare(backSpy.count, 1);
        compare(chosenSpy.count, 0);
    }

    function test_withNoOutputsItSaysSo() {
        const page = makePage({ outputs: [], current: null });

        compare(rows(page).length, 0);
        verify(findChild(page, "noAudioOutputs").visible);
    }
}
