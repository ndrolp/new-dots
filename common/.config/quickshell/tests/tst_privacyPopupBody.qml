import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config/Motion.js" as Motion

// The privacy indicator's popup: the apps using the microphone and a
// camera, listed under each device kind in use.
TestCase {
    name: "PrivacyPopupBody"
    width: 400
    height: 400
    // Shown, so that `visible` tells what the popup shows.
    visible: true
    when: windowShown

    QtObject {
        id: barAppearance

        property int radius: 12
        property int textSize: 13
        property int iconSize: 13
        readonly property var motion: Motion.motion(true)
    }

    // Stands in for services/DeviceCaptures.qml.
    Component {
        id: fakeCaptures

        QtObject {
            property var captures: ({ microphone: [], camera: [] })
        }
    }

    Component {
        id: popupBody

        Panels.PrivacyPopupBody {
            appearance: barAppearance
            width: 300
        }
    }

    function make(captures) {
        const service = createTemporaryObject(fakeCaptures, this, { captures: captures });
        return createTemporaryObject(popupBody, this, { deviceCaptures: service });
    }

    // The visible texts under `item`, in the order they are laid out.
    function shownTexts(item) {
        const texts = [];
        const walk = node => {
            if (!node.visible)
                return;
            if (typeof node.text === "string" && node.text !== "")
                texts.push(node.text);
            for (let i = 0; i < node.children.length; i++)
                walk(node.children[i]);
        };
        walk(item);
        return texts;
    }

    function test_itListsTheAppsUnderEachDeviceKind() {
        const body = make({ microphone: ["Firefox", "Discord"], camera: ["Firefox"] });

        compare(shownTexts(body), ["󰍬", "Microphone", "Firefox", "Discord", "󰕧", "Camera", "Firefox"]);
    }

    function test_aDeviceKindNoAppUsesIsNotListed() {
        const body = make({ microphone: [], camera: ["obs"] });

        compare(shownTexts(body), ["󰕧", "Camera", "obs"]);
    }

    function test_itFollowsTheAppsAsTheyChange() {
        const body = make({ microphone: ["Discord"], camera: [] });

        body.deviceCaptures.captures = { microphone: [], camera: ["obs"] };

        compare(shownTexts(body), ["󰕧", "Camera", "obs"]);
    }

    // The popup may still be open as the last app stops.
    function test_withNothingCapturedItSaysSo() {
        const body = make({ microphone: [], camera: [] });

        compare(shownTexts(body), ["Nothing uses the microphone or a camera"]);
    }
}
