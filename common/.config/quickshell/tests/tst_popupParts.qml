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
        id: barAppearance

        property int radius: 12
        property int textSize: 13
    }

    Component {
        id: title

        Panels.PopupTitle {
            appearance: barAppearance
            text: "Bluetooth"
        }
    }

    Component {
        id: label

        Panels.PopupLabel {
            appearance: barAppearance
            text: "Connected"
        }
    }

    Component {
        id: row

        Panels.PopupRow {
            appearance: barAppearance
            width: 200
            height: 40
        }
    }

    Component {
        id: button

        Panels.PopupButton {
            appearance: barAppearance
            width: 120
            label: "Scan"
        }
    }

    Component {
        id: popupSwitch

        Panels.PopupSwitch {
            appearance: barAppearance
        }
    }

    Component {
        id: header

        Item {
            property alias header: popupHeader

            width: 300

            Panels.PopupHeader {
                id: popupHeader

                appearance: barAppearance
                icon: "󰂯"
                title: "Bluetooth"
                subtitle: "2 connected"
            }
        }
    }

    Component {
        id: progress

        Panels.PopupProgress {
            appearance: barAppearance
            width: 200
        }
    }

    Component {
        id: outputName

        Panels.AudioOutputName {
            appearance: barAppearance
            width: 200
        }
    }

    function audioOutput(nickname, port) {
        return {
            nickname: nickname,
            description: "Core Ultra 200V Series Processors HD Audio",
            name: "alsa_output.pci-0000_00_1f.3",
            properties: { "device.profile.description": port }
        };
    }

    // The text item showing `text` inside `item`.
    function textOf(item, text) {
        if (item.text === text)
            return item;
        for (let i = 0; i < item.children.length; i++) {
            const found = textOf(item.children[i], text);
            if (found)
                return found;
        }
        return null;
    }

    function make(component, properties) {
        return createTemporaryObject(component, this, Object.assign({ appearance: barAppearance }, properties || {}));
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
        const headerTitle = textOf(holder.header, "Bluetooth");
        const headerSubtitle = textOf(holder.header, "2 connected");

        compare(holder.header.width, 300);
        compare(headerTitle.font.pixelSize, 14);
        compare(headerSubtitle.font.pixelSize, 11);
        verify(holder.header.implicitHeight >= headerTitle.implicitHeight + headerSubtitle.implicitHeight);
    }

    function test_popupTextUsesTheThemeFont() {
        const holder = createTemporaryObject(header, this);

        compare(make(title).font.family, theme.fontFamily);
        compare(make(label).font.family, theme.fontFamily);
        compare(textOf(make(button), "Scan").font.family, theme.fontFamily);
        compare(textOf(holder.header, "󰂯").font.family, theme.fontFamily);
        compare(textOf(holder.header, "Bluetooth").font.family, theme.fontFamily);
    }

    function test_progressIsFilledUpToItsFractionAndNoFurther() {
        const item = make(progress, { fraction: 0.25 });

        compare(item.children[0].width, 50);
        item.fraction = 3;
        compare(item.children[0].width, 200);
    }

    // An audio output is named on two lines, its label over its muted port,
    // in a row tall enough for both.
    function test_anAudioOutputShowsItsPortUnderItsLabel() {
        const item = make(outputName, { output: audioOutput("Q27G42XE", "HDMI / DisplayPort 1 Output") });
        const outputLabel = textOf(item, "Q27G42XE");
        const outputPort = textOf(item, "HDMI / DisplayPort 1 Output");

        compare(outputLabel.color, theme.text);
        compare(outputLabel.font.pixelSize, 13);
        verify(outputPort !== null);
        compare(outputPort.color, theme.textMuted);
        compare(outputPort.font.pixelSize, 10);
        compare(item.rowHeight, 42);
    }

    function test_anAudioOutputWithoutAPortIsASingleLineInAShorterRow() {
        const item = make(outputName, { output: audioOutput("Headphones", "Headphones") });

        compare(textOf(item, "Headphones"), item.children[0]);
        compare(item.children[1].text, "");
        compare(item.rowHeight, 36);
    }

    function test_aHighlightedAudioOutputHasItsLabelInTheAccent() {
        const item = make(outputName, {
            output: audioOutput("Q27G42XE", ""),
            highlighted: true,
            labelSize: 12
        });
        const outputLabel = textOf(item, "Q27G42XE");

        compare(outputLabel.color, theme.accent);
        compare(outputLabel.font.pixelSize, 12);
    }
}
