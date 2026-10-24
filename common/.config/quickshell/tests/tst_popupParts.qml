import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config" as Config

// The parts every popup and floating dialog is built from: weight hierarchy
// (only titles are bold), rows that show only on hover, and controls that
// follow the bar's text size and radius.
// Pointer events don't reach items under qmltestrunner offscreen, so taps and
// hover are checked in the renders instead.
TestCase {
    name: "PopupParts"
    width: 400
    height: 400
    when: windowShown

    Config.Theme {
        id: theme
    }

    QtObject {
        id: appearance

        property int radius: 12
        property int textSize: 13
    }

    Component {
        id: title

        Panels.PopupTitle {
            appearance: appearance
            text: "Bluetooth"
        }
    }

    Component {
        id: label

        Panels.PopupLabel {
            appearance: appearance
            text: "Connected"
        }
    }

    Component {
        id: row

        Panels.PopupRow {
            appearance: appearance
            width: 200
            height: 40
        }
    }

    Component {
        id: button

        Panels.PopupButton {
            appearance: appearance
            width: 120
            label: "Scan"
        }
    }

    Component {
        id: popupSwitch

        Panels.PopupSwitch {
            appearance: appearance
        }
    }

    Component {
        id: header

        Item {
            property alias header: popupHeader

            width: 300

            Panels.PopupHeader {
                id: popupHeader

                appearance: appearance
                icon: "󰂯"
                title: "Bluetooth"
                subtitle: "2 connected"
            }
        }
    }

    Component {
        id: progress

        Panels.PopupProgress {
            appearance: appearance
            width: 200
        }
    }

    function make(component, properties) {
        return createTemporaryObject(component, this, Object.assign({ appearance: appearance }, properties || {}));
    }

    function test_aTitleIsBoldAndSlightlyLargerThanText() {
        const item = make(title);

        verify(item.font.bold);
        compare(item.font.pixelSize, 14);
        compare(item.color, theme.text);
    }

    function test_aLabelIsRegularMutedAndSmaller() {
        const item = make(label);

        verify(!item.font.bold);
        compare(item.font.pixelSize, 11);
        compare(item.color, theme.textMuted);
    }

    function test_aRowAtRestIsTransparentWithTheBarRadius() {
        const item = make(row);

        compare(item.color, Qt.rgba(0, 0, 0, 0));
        compare(item.radius, 12);
        verify(!item.hovered);
    }

    function test_aButtonIsARowWithItsLabelAtBodySize() {
        const item = make(button);

        compare(item.height, 30);
        compare(item.color, Qt.rgba(0, 0, 0, 0));
        compare(item.labelSize, 12);
        compare(item.labelColor, theme.text);
    }

    function test_anUncheckedSwitchIsOnlyOutlined() {
        const item = make(popupSwitch);

        compare(item.color, Qt.rgba(0, 0, 0, 0));
        compare(item.border.color, theme.border);
    }

    function test_aCheckedSwitchIsFilledWithTheAccent() {
        const item = make(popupSwitch, { checked: true });

        tryCompare(item, "color", theme.accent, 500);
    }

    function test_aHeaderFillsItsParentAndFitsTitleAndSubtitle() {
        const holder = createTemporaryObject(header, this);

        compare(holder.header.width, 300);
        verify(holder.header.implicitHeight > 14 + 11);
    }

    function test_progressIsFilledUpToItsFractionAndNoFurther() {
        const item = make(progress, { fraction: 0.25 });

        compare(item.children[0].width, 50);
        item.fraction = 3;
        compare(item.children[0].width, 200);
    }
}
