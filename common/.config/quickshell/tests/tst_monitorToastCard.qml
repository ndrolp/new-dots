import QtQuick
import QtTest
import "../components/panels" as Panels

// The toast for an unknown combination: the quick switch's choices, and Arrange.
Item {
    id: root

    width: 400
    height: 300

    readonly property var choices: [{ kind: "extend", label: "Extend" }, { kind: "mirror", label: "Mirror" },
        { kind: "only", label: "AOC only", port: "DP-2" }]

    QtObject {
        id: testAppearance

        readonly property int radius: 8
        readonly property int textSize: 12
        readonly property var motion: ({ short: 0 })
    }

    Panels.MonitorToastCard {
        id: card

        appearance: testAppearance
        choices: root.choices
    }

    Panels.MonitorNoticeCard {
        id: notice

        y: 200
        appearance: testAppearance
        message: "Hyprland didn't apply the monitor setup."
    }

    SignalSpy {
        id: noticeDismiss

        target: notice
        signalName: "dismissAsked"
    }

    SignalSpy {
        id: chosen

        target: card
        signalName: "chosen"
    }

    SignalSpy {
        id: arrange

        target: card
        signalName: "arrangeAsked"
    }

    SignalSpy {
        id: dismiss

        target: card
        signalName: "dismissAsked"
    }

    TestCase {
        name: "MonitorToastCard"
        when: windowShown

        function button(label) {
            return findChild(card, "toast " + label);
        }

        function init() {
            chosen.clear();
            arrange.clear();
            dismiss.clear();
        }

        function test_everyChoiceIsOffered() {
            for (const label of ["Extend", "Mirror", "AOC only", "Arrange…"])
                verify(button(label) !== null, label);
        }

        function test_clickingAChoiceHandsItOver() {
            mouseClick(button("AOC only"));
            compare(chosen.count, 1);
            compare(chosen.signalArguments[0][0].port, "DP-2");
        }

        function test_arrangeAsksForDisplays() {
            mouseClick(button("Arrange…"));
            compare(arrange.count, 1);
            compare(chosen.count, 0);
        }

        function test_itCanBeDismissed() {
            mouseClick(button("Dismiss"));
            compare(dismiss.count, 1);
            compare(chosen.count, 0);
        }

        function test_aNoticeSaysWhatFailed() {
            compare(findChild(notice, "card hint").text, "Hyprland didn't apply the monitor setup.");
        }

        function test_aNoticeCanBeDismissed() {
            noticeDismiss.clear();
            mouseClick(findChild(notice, "notice Dismiss"));
            compare(noticeDismiss.count, 1);
        }
    }
}
