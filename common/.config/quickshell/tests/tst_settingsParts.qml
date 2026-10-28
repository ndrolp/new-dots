import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config" as Config
import "../config/Motion.js" as Motion

// The parts every section of the settings panel is built from. They share the
// popups' minimal look (transparent, hairline borders, accent for focus and
// choice, only the section title bold), a little larger for a big window.
// Pointer events don't reach items under qmltestrunner offscreen, so taps and
// hover are checked in the renders instead; typing is checked with key events.
TestCase {
    name: "SettingsParts"
    width: 600
    height: 400
    when: windowShown

    Config.Theme {
        id: theme
    }

    QtObject {
        id: barAppearance

        property int radius: 12
        property int textSize: 13
        readonly property var motion: Motion.motion(false)
    }

    // The same settings with reduce motion on.
    QtObject {
        id: reducedAppearance

        property int radius: 12
        property int textSize: 13
        readonly property var motion: Motion.motion(true)
    }

    Component {
        id: input

        Panels.SettingsInput {
            width: 200
        }
    }

    Component {
        id: heading

        Panels.SettingsHeading {
            text: "Size & spacing"
        }
    }

    Component {
        id: label

        Panels.SettingsLabel {
            text: "Bar height"
        }
    }

    Component {
        id: hint

        Panels.SettingsHint {
            text: "Fills in the sizes below"
        }
    }

    Component {
        id: row

        Panels.SettingsRow {
            width: 260
            height: 44

            Panels.SettingsLabel {
                appearance: barAppearance
                text: "Bar"
            }
        }
    }

    Component {
        id: switchRow

        Panels.SettingsSwitchRow {
            width: 260
            label: "Transparent bar"
        }
    }

    Component {
        id: choice

        Panels.SettingsChoice {
            width: 302
            options: [
                { label: "Compact", value: "compact" },
                { label: "Balanced", value: "balanced" },
                { label: "Spacious", value: "spacious" }
            ]
        }
    }

    Component {
        id: number

        Panels.SettingsNumber {
            width: 280
            label: "Bar height"
            from: 24
            to: 56
            value: 32
        }
    }

    Component {
        id: labelledField

        Panels.SettingsField {
            width: 280
            label: "Date format"

            Panels.SettingsChoice {
                width: parent.width
                appearance: barAppearance
                options: [{ label: "Full", value: "full" }, { label: "Short", value: "short" }]
            }
        }
    }

    Component {
        id: moveButtons

        Panels.SettingsMoveButtons {}
    }

    SignalSpy {
        id: movedUpSpy

        signalName: "movedUp"
    }

    SignalSpy {
        id: movedDownSpy

        signalName: "movedDown"
    }

    Component {
        id: monitorChoice

        Panels.SettingsMonitorChoice {
            width: 400
            displays: [
                { description: "Dell Inc. DELL U2720Q 1234", name: "DELL U2720Q", portrait: false },
                { description: "Philips Consumer Electronics 243V 5678", name: "243V", portrait: true }
            ]
        }
    }

    SignalSpy {
        id: chosenSpy

        signalName: "chosen"
    }

    Component {
        id: grid

        Panels.SettingsGrid {
            width: 500

            Repeater {
                model: 3

                delegate: Rectangle {
                    width: parent.cellWidth
                    height: 40
                }
            }
        }
    }

    Component {
        id: button

        Panels.SettingsButton {
            label: "Done"
        }
    }

    SignalSpy {
        id: editedSpy

        signalName: "edited"
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

    function test_aFieldIsTransparentWithAHairlineBorder() {
        const item = make(input);

        compare(item.height, 32);
        verify(!item.font.bold);
        compare(item.font.family, theme.fontFamily);
        compare(item.background.color, Qt.rgba(0, 0, 0, 0));
        compare(item.background.border.color, theme.border);
        compare(item.background.border.width, 1);
    }

    function test_aFocusedFieldHasAnAccentBorder() {
        const item = make(input);

        item.forceActiveFocus();
        compare(item.background.border.color, theme.accent);
    }

    // Group headings are small, muted and uppercase; setting labels are in
    // the normal text color; hints and values are muted. None is bold.
    function test_aGroupHeadingIsSmallMutedUppercase() {
        const item = make(heading);

        compare(item.font.capitalization, Font.AllUppercase);
        compare(item.font.pixelSize, 11);
        compare(item.color, theme.textMuted);
        verify(!item.font.bold);
    }

    function test_aSettingLabelIsRegularInTheNormalTextColor() {
        const item = make(label);

        compare(item.font.capitalization, Font.MixedCase);
        compare(item.font.pixelSize, 13);
        compare(item.color, theme.text);
        verify(!item.font.bold);
        compare(item.font.family, theme.fontFamily);
    }

    function test_aHintIsMutedAndSlightlySmaller() {
        const item = make(hint);

        compare(item.font.pixelSize, 12);
        compare(item.color, theme.textMuted);
        verify(!item.font.bold);
    }

    // A list row is full width and transparent until hovered, with the
    // settings' corner radius; what it shows is up to its owner.
    function test_aRowIsTransparentAtRestAndShowsItsContent() {
        const item = make(row);

        compare(item.color, Qt.rgba(0, 0, 0, 0));
        compare(item.radius, 12);
        verify(!item.hovered);
        verify(textOf(item, "Bar"));
    }

    // A switch row is a row like any other: its label on the left and a
    // switch on the right.
    function test_aSwitchRowIsARow() {
        const item = make(switchRow);

        compare(item.radius, 12);
        verify(item.hovered !== undefined);
    }

    // A switch row is transparent until hovered, its label on the left and a
    // hairline pill switch on the right.
    function test_aSwitchRowAtRestIsTransparentWithItsLabelAndAnOutlinedSwitch() {
        const item = make(switchRow);
        const rowLabel = textOf(item, "Transparent bar");

        compare(item.color, Qt.rgba(0, 0, 0, 0));
        compare(item.height, 40);
        compare(rowLabel.color, theme.text);
        verify(!rowLabel.font.bold);
        compare(item.switchItem.color, Qt.rgba(0, 0, 0, 0));
        compare(item.switchItem.border.color, theme.border);
        verify(item.switchItem.x > rowLabel.x + rowLabel.width);
    }

    function test_aCheckedSwitchRowFillsItsSwitchWithTheAccent() {
        const item = make(switchRow, { checked: true });

        tryCompare(item.switchItem, "color", theme.accent, 500);
    }

    // Turning a switch on eases its fill and knob over, unless reduce motion
    // is on: then the switch is on at once.
    function test_turningASwitchOnEasesItOver() {
        const item = make(switchRow);

        item.checked = true;
        verify(!Qt.colorEqual(item.switchItem.color, theme.accent));
        tryCompare(item.switchItem, "color", theme.accent, 500);
    }

    function test_withReduceMotionASwitchIsOnAtOnce() {
        const item = make(switchRow, { appearance: reducedAppearance });
        const knob = item.switchItem.children[0];

        item.checked = true;
        compare(item.switchItem.color, theme.accent);
        compare(knob.x, item.switchItem.width - knob.width - 3);
    }

    function test_withReduceMotionTheChosenOptionIsMarkedAtOnce() {
        const item = make(choice, { appearance: reducedAppearance, value: "compact" });

        item.value = "balanced";
        compare(textOf(item, "Balanced").parent.color, theme.surfaceHover);
        compare(textOf(item, "Compact").parent.color, Qt.rgba(0, 0, 0, 0));
    }

    // A segmented choice is one hairline-bordered control split evenly
    // between its options.
    function test_aChoiceIsOneOutlinedControlSplitBetweenItsOptions() {
        const item = make(choice);

        compare(item.height, 32);
        compare(item.color, Qt.rgba(0, 0, 0, 0));
        compare(item.border.color, theme.border);
        compare(item.border.width, 1);
        compare(textOf(item, "Compact").parent.width, 100);
        compare(textOf(item, "Spacious").parent.width, 100);
    }

    function test_theChosenOptionHasAccentTextAndAFaintFill() {
        const item = make(choice, { value: "balanced" });
        const chosen = textOf(item, "Balanced");
        const other = textOf(item, "Compact");

        compare(chosen.color, theme.accent);
        compare(chosen.parent.color, theme.surfaceHover);
        compare(other.color, theme.text);
        compare(other.parent.color, Qt.rgba(0, 0, 0, 0));
        verify(!chosen.font.bold);
    }

    // Sizes that match no preset leave every option unmarked.
    function test_aValueMatchingNoOptionMarksNone() {
        const item = make(choice, { value: "" });

        compare(textOf(item, "Compact").color, theme.text);
        compare(textOf(item, "Balanced").color, theme.text);
        compare(textOf(item, "Spacious").color, theme.text);
    }

    // A number setting is its label on top, then the slider and a small
    // number field side by side on one line.
    function test_aNumberSettingHasItsLabelOverASliderAndASmallField() {
        const item = make(number);
        const numberLabel = textOf(item, "Bar height");

        compare(numberLabel.color, theme.text);
        compare(item.field.width, 56);
        compare(item.field.text, "32");
        compare(item.field.x + item.field.width, 280);
        verify(item.slider.width > 150);
        verify(item.slider.x + item.slider.width < item.field.x);
        verify(item.slider.mapToItem(item, 0, 0).y >= numberLabel.y + numberLabel.height);
        compare(item.slider.y + item.slider.height / 2, item.field.y + item.field.height / 2);
        compare(item.slider.value, 32);
    }

    function test_typingANumberInRangeSavesIt() {
        const item = make(number);
        editedSpy.target = item;
        editedSpy.clear();

        item.field.forceActiveFocus();
        item.field.selectAll();
        keyClick("4");
        keyClick("0");
        keyClick(Qt.Key_Return);

        compare(editedSpy.count, 1);
        compare(editedSpy.signalArguments[0][0], 40);
    }

    // Return finishes the edit and so does leaving the field after it: the
    // number is still saved only once.
    function test_typingANumberThenLeavingTheFieldSavesItOnce() {
        const item = make(number);
        editedSpy.target = item;
        editedSpy.clear();

        item.field.forceActiveFocus();
        item.field.selectAll();
        keyClick("4");
        keyClick("0");
        keyClick(Qt.Key_Return);
        item.field.focus = false;

        compare(editedSpy.count, 1);
    }

    function test_leavingANumberFieldUnchangedSavesNothing() {
        const item = make(number);
        editedSpy.target = item;
        editedSpy.clear();

        item.field.forceActiveFocus();
        keyClick(Qt.Key_Return);
        item.field.focus = false;

        compare(editedSpy.count, 0);
    }

    // A field asks to save its text when the edit is finished, once per
    // change, however the edit is finished.
    function test_aFieldAsksToSaveItsTextOncePerChange() {
        const item = make(input, { text: "GitHub" });
        editedSpy.target = item;
        editedSpy.clear();

        item.forceActiveFocus();
        item.selectAll();
        keyClick("G");
        keyClick("o");
        compare(editedSpy.count, 0);
        keyClick(Qt.Key_Return);
        item.focus = false;

        compare(editedSpy.count, 1);
        compare(editedSpy.signalArguments[0][0], "Go");
    }

    function test_aNumberOutOfRangeIsRejected() {
        const item = make(number);
        editedSpy.target = item;
        editedSpy.clear();

        item.field.forceActiveFocus();
        item.field.selectAll();
        keyClick("9");
        keyClick("9");
        keyClick(Qt.Key_Return);

        compare(editedSpy.count, 0);
    }

    function test_movingTheSliderSavesTheNumber() {
        const item = make(number);
        editedSpy.target = item;
        editedSpy.clear();

        item.slider.forceActiveFocus();
        keyClick(Qt.Key_Right);

        compare(editedSpy.count, 1);
        compare(editedSpy.signalArguments[0][0], 33);
    }

    // Whoever owns the setting saves it and sets `value`; both controls follow.
    function test_aNewValueShowsInBothControls() {
        const item = make(number);

        item.value = 48;

        compare(item.field.text, "48");
        compare(item.slider.value, 48);
    }

    // A setting whose control has no name of its own has its label on top,
    // the control right under it, full width.
    function test_aLabelledSettingHasItsLabelOverItsControl() {
        const item = make(labelledField);
        const fieldLabel = textOf(item, "Date format");
        const control = item.children.filter(child => child.options !== undefined)[0];

        compare(fieldLabel.color, theme.text);
        compare(fieldLabel.font.pixelSize, 13);
        compare(control.width, 280);
        compare(control.y, fieldLabel.height + 6);
    }

    // Moving something up or down a list is a pair of quiet arrow buttons;
    // an end of the list disables the arrow past it.
    function test_moveButtonsAreAPairOfQuietArrows() {
        const item = make(moveButtons);
        const up = item.children.filter(child => child.label === "󰁝")[0];
        const down = item.children.filter(child => child.label === "󰁅")[0];
        movedUpSpy.target = item;
        movedDownSpy.target = item;
        movedUpSpy.clear();
        movedDownSpy.clear();

        compare(up.color, Qt.rgba(0, 0, 0, 0));
        compare(up.width, 32);
        verify(up.x < down.x);
        up.activated();
        down.activated();
        compare(movedUpSpy.count, 1);
        compare(movedDownSpy.count, 1);
    }

    function test_theEndsOfAListDisableTheArrowPastThem() {
        const item = make(moveButtons, { canMoveUp: false });
        const up = item.children.filter(child => child.label === "󰁝")[0];
        const down = item.children.filter(child => child.label === "󰁅")[0];

        verify(!up.enabled);
        verify(down.enabled);
        item.canMoveDown = false;
        verify(!down.enabled);
    }

    // A connected monitor is chosen by its short name, with an icon for how
    // it stands, so the options don't elide; settings are stored under its
    // description.
    function test_aMonitorChoiceNamesEachMonitorShortly() {
        const item = make(monitorChoice, { value: "Philips Consumer Electronics 243V 5678" });

        compare(item.options, [
            { label: "󰍺 DELL U2720Q", value: "Dell Inc. DELL U2720Q 1234" },
            { label: "󰍹 243V", value: "Philips Consumer Electronics 243V 5678" }
        ]);
        compare(textOf(item, "󰍹 243V").color, theme.accent);
    }

    // A monitor that isn't connected (or none chosen yet) gives way to the
    // first connected one.
    function test_aMonitorChoiceAsksForTheFirstMonitorWhenTheChosenOneIsGone() {
        const item = make(monitorChoice, { value: "Philips Consumer Electronics 243V 5678" });
        chosenSpy.target = item;
        chosenSpy.clear();

        item.displays = item.displays.slice(0, 1);

        compare(chosenSpy.count, 1);
        compare(chosenSpy.signalArguments[0][0], "Dell Inc. DELL U2720Q 1234");
    }

    // A small label suits fields packed into a list row: muted and a little
    // smaller, like a hint.
    function test_aSmallLabelIsMutedAndSlightlySmaller() {
        const item = make(labelledField, { small: true });
        const fieldLabel = textOf(item, "Date format");

        compare(fieldLabel.color, theme.textMuted);
        compare(fieldLabel.font.pixelSize, 12);
        verify(!fieldLabel.font.bold);
    }

    // Short controls sit two per line, in columns of equal width with a gap
    // between them; an odd one out starts the next line.
    function test_aGridPlacesShortControlsTwoPerLine() {
        const item = createTemporaryObject(grid, this);
        const cells = item.children.filter(child => child instanceof Rectangle);

        compare(item.cellWidth, 238);
        compare(cells[0].x, 0);
        compare(cells[1].x, 262);
        compare(cells[1].y, cells[0].y);
        compare(cells[2].x, 0);
        verify(cells[2].y >= cells[0].y + 40);
    }

    // A quiet text button: no fill at rest, its label in the normal text
    // color, as tall as a field.
    function test_aButtonIsQuietText() {
        const item = make(button);
        const buttonLabel = textOf(item, "Done");

        compare(item.height, 32);
        compare(item.color, Qt.rgba(0, 0, 0, 0));
        compare(buttonLabel.color, theme.text);
        compare(buttonLabel.font.pixelSize, 13);
        verify(!buttonLabel.font.bold);
        verify(item.width >= buttonLabel.implicitWidth + 24);
    }

    // A button that can't be pressed now is dimmed, the same for every
    // button, and can't be pressed.
    function test_aDisabledButtonIsDimmedAndCannotBeTapped() {
        const item = make(button);
        const tap = item.data.filter(child => child instanceof TapHandler)[0];

        compare(item.opacity, 1);
        verify(tap.enabled);

        item.enabled = false;

        compare(item.opacity, 0.4);
        verify(!tap.enabled);
    }
}
