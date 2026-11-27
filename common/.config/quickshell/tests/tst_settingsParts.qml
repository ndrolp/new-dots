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
        id: select

        Panels.SettingsSelect {
            options: [
                { label: "Hidden", value: "hidden" },
                { label: "On battery", value: "onBattery" },
                { label: "Live in row", value: "liveRow" }
            ]
        }
    }

    Component {
        id: choiceList

        Panels.SettingsChoiceList {
            width: 302
            options: [{ label: "Alpha", value: "a" }, { label: "Bravo", value: "b" }]
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
        id: switchGrid

        Panels.SettingsGrid {
            width: 400

            Panels.SettingsSwitchRow {
                width: parent.cellWidth
                appearance: barAppearance
                label: "Notifications in the capsule"
            }

            Panels.SettingsSwitchRow {
                width: parent.cellWidth
                appearance: barAppearance
                label: "Capsule vertical padding"
            }
        }
    }

    Component {
        id: card

        Panels.SettingsCard {
            width: 400
            title: "Animations"

            Panels.SettingsSwitchRow {
                width: parent.width
                appearance: barAppearance
                label: "Reduce motion"
            }
        }
    }

    Component {
        id: button

        Panels.SettingsButton {
            label: "Done"
        }
    }

    Component {
        id: controlsInCard

        Panels.SettingsCard {
            width: 400

            Panels.SettingsButton {
                appearance: reducedAppearance
                label: "Done"
            }

            Panels.SettingsChoice {
                width: 300
                appearance: reducedAppearance
                value: "compact"
                options: [{ label: "Compact", value: "compact" }, { label: "Spacious", value: "spacious" }]
            }
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

    // The HoverHandler `item` reacts to the pointer with.
    function hoverOf(item) {
        return item.data.filter(child => child instanceof HoverHandler)[0];
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
        tryCompare(item.background.border, "color", theme.accent, 500);
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
        verify(!item.hovering);
        verify(textOf(item, "Bar"));
    }

    // A switch row is a row like any other: its label on the left and a
    // switch on the right.
    function test_aSwitchRowIsARow() {
        const item = make(switchRow);

        compare(item.radius, 12);
        verify(item.hovering !== undefined);
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

    // A label longer than its space wraps to further lines instead of
    // eliding, and the row grows to hold it, clear of its switch.
    function test_aLongLabelInANarrowSwitchRowWrapsClearOfItsSwitch() {
        const item = make(switchRow, { width: 180, label: "Notifications in the capsule" });
        const rowLabel = textOf(item, "Notifications in the capsule");

        compare(rowLabel.elide, Text.ElideNone);
        verify(rowLabel.lineCount > 1);
        verify(!rowLabel.truncated);
        verify(rowLabel.x + rowLabel.width <= item.switchItem.x);
        verify(rowLabel.y >= 0);
        verify(rowLabel.y + rowLabel.height <= item.height);
    }

    // A label on top of its control wraps too, and pushes the control down.
    function test_aLongLabelOnTopOfItsControlWrapsAndPushesItDown() {
        const item = make(number, { width: 120, label: "Capsule vertical padding" });
        const fieldLabel = textOf(item, "Capsule vertical padding");

        compare(fieldLabel.elide, Text.ElideNone);
        verify(fieldLabel.lineCount > 1);
        verify(fieldLabel.mapToItem(item, 0, fieldLabel.height).y <= item.slider.mapToItem(item, 0, 0).y);
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
        compare(textOf(item, "Balanced").parent.color, theme.cardHover);
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
        compare(chosen.parent.color, theme.cardHover);
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

    // A selector is one hairline-bordered button showing only the chosen
    // option's label; its options open in a list only when pressed.
    function test_aSelectorShowsOnlyTheChosenOption() {
        const item = make(select, { value: "onBattery" });

        compare(item.height, 32);
        compare(item.border.color, theme.border);
        compare(item.border.width, 1);
        verify(textOf(item, "On battery") !== null);
        verify(!item.open);
    }

    // A selector whose value matches no option shows no label.
    function test_aSelectorMatchingNoOptionShowsNone() {
        const item = make(select, { value: "" });

        compare(item.chosenOption, null);
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

    // Cells too narrow to hold a label and its control side by side make it
    // one column: each control takes the whole width, one per line.
    function test_aNarrowGridShowsOneColumn() {
        const item = createTemporaryObject(switchGrid, this);
        const cells = item.children.filter(child => child.switchItem !== undefined);

        compare(item.columns, 1);
        compare(item.cellWidth, 400);
        compare(cells[0].x, 0);
        compare(cells[1].x, 0);
        verify(cells[1].y >= cells[0].y + cells[0].height);
    }

    // Wide enough, the same grid is two columns again, and a long label
    // wraps inside its cell, clear of its switch and of the next cell.
    function test_aWideGridShowsTwoColumnsAndWrapsALongLabelInItsCell() {
        const item = createTemporaryObject(switchGrid, this, { width: 560 });
        const cells = item.children.filter(child => child.switchItem !== undefined);
        const longLabel = textOf(cells[0], "Notifications in the capsule");

        compare(item.columns, 2);
        compare(cells[1].y, cells[0].y);
        verify(cells[0].x + cells[0].width <= cells[1].x);
        verify(longLabel.lineCount > 1);
        verify(longLabel.x + longLabel.width <= cells[0].switchItem.x);
        verify(longLabel.y + longLabel.height <= cells[0].height);
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

    // A headed group sits in a card: a hairline border, a fill one step
    // lighter than the panel, its heading inside at the top, 16px padding.
    function test_aCardIsAHairlineBorderedHalfTransparentLighterFill() {
        const item = make(card);

        compare(item.color, Qt.rgba(theme.surfaceHover.r, theme.surfaceHover.g, theme.surfaceHover.b, 0.5));
        compare(item.border.color, theme.border);
        compare(item.border.width, 1);
        compare(item.radius, 12);
    }

    function test_aCardHasItsHeadingInsideAtTheTopAndItsContentPaddedBelow() {
        const item = make(card);
        const cardHeading = textOf(item, "Animations");
        const content = textOf(item, "Reduce motion").parent;
        const headingTop = cardHeading.mapToItem(item, 0, 0);
        const contentTop = content.mapToItem(item, 0, 0);

        compare(cardHeading.font.capitalization, Font.AllUppercase);
        compare(headingTop.x, 16);
        compare(headingTop.y, 16);
        compare(contentTop.x, 16);
        verify(contentTop.y >= headingTop.y + cardHeading.height);
        compare(content.width, 400 - 32);
        compare(item.height, contentTop.y + content.height + 16);
    }

    // The controls sit on a card, so their hover and chosen fill must stand
    // out from the card's own fill.
    function test_hoveredAndChosenFillsStandOutFromTheCardTheyAreOn() {
        const item = make(controlsInCard);
        const hoveredButton = textOf(item, "Done").parent;
        const chosen = textOf(item, "Compact").parent;

        hoveredButton.hovering = true;
        verify(!Qt.colorEqual(hoveredButton.color, item.color),
               "hovered button fill " + hoveredButton.color + " is the card's " + item.color);
        verify(!Qt.colorEqual(chosen.color, item.color),
               "chosen option fill " + chosen.color + " is the card's " + item.color);
    }

    // The card itself has no hover; only the controls in it react.
    function test_aCardHasNoHover() {
        const item = make(card);

        compare(item.data.filter(child => child instanceof HoverHandler).length, 0);
        compare(item.hovering, undefined);
    }

    // Every clickable part of the panel answers the pointer the same way: a
    // faint fill and a pointing hand. A hovered row is no exception.
    function test_aHoveredRowTakesTheFaintFill() {
        const item = make(row, { appearance: reducedAppearance });

        item.hovering = true;
        compare(item.color, theme.cardHover);
    }

    function test_aRowThatIsClickedShowsAPointingHand() {
        const item = make(row);

        compare(hoverOf(item).cursorShape, Qt.ArrowCursor);
        item.clickable = true;
        compare(hoverOf(item).cursorShape, Qt.PointingHandCursor);
    }

    function test_aSwitchRowIsClicked() {
        const item = make(switchRow);

        verify(item.clickable);
    }

    function test_aHoveredButtonTakesTheFaintFillAndAPointingHand() {
        const item = make(button, { appearance: reducedAppearance });

        item.hovering = true;
        compare(item.color, theme.cardHover);
        compare(hoverOf(item).cursorShape, Qt.PointingHandCursor);
    }

    // A bordered control's border turns accent while hovered; the option
    // under the pointer takes the faint fill.
    function test_aHoveredChoiceHasAnAccentBorderAndFillsTheOptionUnderThePointer() {
        const item = make(choice, { appearance: reducedAppearance, value: "compact" });
        const option = textOf(item, "Spacious").parent;

        item.hovering = true;
        compare(item.border.color, theme.accent);
        option.hovering = true;
        compare(option.color, theme.cardHover);
        compare(hoverOf(option).cursorShape, Qt.PointingHandCursor);
    }

    // A chip of a longer choice is bordered on its own: hovered, it takes
    // the faint fill and an accent border.
    function test_aHoveredChipTakesTheFaintFillAndAnAccentBorder() {
        const item = make(choiceList, { appearance: reducedAppearance, value: "a" });
        const chip = textOf(item, "Bravo").parent;

        compare(chip.border.color, theme.border);
        chip.hovering = true;
        compare(chip.color, theme.cardHover);
        compare(chip.border.color, theme.accent);
        compare(hoverOf(chip).cursorShape, Qt.PointingHandCursor);
    }

    // A number box is bordered too.
    function test_aHoveredFieldHasAnAccentBorderAndTheFaintFill() {
        const item = make(input, { appearance: reducedAppearance });

        item.hovering = true;
        compare(item.background.border.color, theme.accent);
        compare(item.background.color, theme.cardHover);
    }

    // A slider's thumb grows under the pointer.
    function test_aHoveredSliderGrowsItsThumb() {
        const item = make(number, { appearance: reducedAppearance });
        const rest = item.slider.handle.width;

        item.slider.hovering = true;
        verify(item.slider.handle.width > rest);
        compare(item.slider.handle.height, item.slider.handle.width);
        compare(hoverOf(item.slider).cursorShape, Qt.PointingHandCursor);
    }

    // A switch brightens while its row is hovered, off or on.
    function test_aHoveredSwitchRowBrightensItsSwitch() {
        const off = make(switchRow, { appearance: reducedAppearance });
        const on = make(switchRow, { appearance: reducedAppearance, checked: true });
        const offBorder = String(off.switchItem.border.color);
        const onFill = String(on.switchItem.color);

        off.hovering = true;
        on.hovering = true;
        verify(off.switchItem.hovering);
        verify(!Qt.colorEqual(off.switchItem.border.color, offBorder));
        verify(!Qt.colorEqual(on.switchItem.color, onFill));
        compare(on.switchItem.color, theme.accentHover);
    }

    // Every hover change eases over with the motion tokens: with reduce
    // motion it is instant, otherwise it takes a moment.
    function test_aHoverEasesInUnlessMotionIsReduced() {
        const item = make(button);

        item.hovering = true;
        verify(!Qt.colorEqual(item.color, theme.cardHover));
        tryCompare(item, "color", theme.cardHover, 500);
    }
}
