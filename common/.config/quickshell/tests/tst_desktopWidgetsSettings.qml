import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config/Motion.js" as Motion
import "../config" as Config
import "../config/DesktopWidgetsModel.js" as DesktopWidgetsModel

// The Desktop Widgets section for one monitor, built from the settings parts:
// a switch row turns each desktop widget on or off, its placement is a
// segmented choice and its other settings sit two per line. Pointer events
// don't reach items under qmltestrunner offscreen, so the parts' signals stand
// in for taps; typing is checked with key events.
TestCase {
    name: "DesktopWidgetsSettings"
    width: 800
    height: 1600
    visible: true
    when: windowShown

    Config.Theme {
        id: theme
    }

    function all(item, predicate, found) {
        found = found || [];
        if (predicate(item))
            found.push(item);
        for (let i = 0; i < item.children.length; i++)
            all(item.children[i], predicate, found);
        return found;
    }

    function switchRow(item, label) {
        return all(item, child => child.label === label && child.switchItem !== undefined)[0];
    }

    function numberCell(item, label) {
        return all(item, child => child.label === label && child.field !== undefined)[0];
    }

    // A fake of the shell's monitors over the real desktop widgets model, so
    // what is saved shows up again in the section.
    Component {
        id: sectionArea

        Item {
            property alias monitors: monitors
            property alias section: section

            width: 700

            QtObject {
                id: appearance

                property int radius: 12
                property int textSize: 13
                readonly property var motion: Motion.motion(false)
            }

            QtObject {
                id: monitors

                property var displaySettings: ({})

                function desktopWidgetsFor(monitorName) {
                    return DesktopWidgetsModel.desktopWidgetsFor(displaySettings, monitorName);
                }

                function desktopWidgetOrder(monitorName) {
                    return DesktopWidgetsModel.desktopWidgetOrder(desktopWidgetsFor(monitorName));
                }

                function setDesktopWidgetSetting(monitorName, widget, key, value) {
                    displaySettings = DesktopWidgetsModel.setDesktopWidgetSetting(
                        displaySettings, monitorName, widget, key, value);
                }

                function setDesktopWidgetsEdgePadding(monitorName, padding) {
                    displaySettings = DesktopWidgetsModel.setEdgePadding(displaySettings, monitorName, padding);
                }

                function moveDesktopWidget(monitorName, widget, offset) {
                    displaySettings = DesktopWidgetsModel.moveDesktopWidget(
                        displaySettings, monitorName, widget, offset);
                }
            }

            Panels.DesktopWidgetsMonitorSettings {
                id: section

                appearance: appearance
                monitors: monitors
                monitorName: "DELL U2720Q"
            }
        }
    }

    function make() {
        const built = createTemporaryObject(sectionArea, this);
        return { monitors: built.monitors, item: built.section };
    }

    function widgetsOf(built) {
        return built.monitors.desktopWidgetsFor("DELL U2720Q");
    }

    function test_aSwitchRowTurnsADesktopWidgetOnForThatMonitorOnly() {
        const built = make();
        const media = switchRow(built.item, "Media");

        verify(media);
        compare(media.checked, false);

        media.toggled();

        compare(widgetsOf(built).media.enabled, true);
        compare(built.monitors.desktopWidgetsFor("Other").media.enabled, false);
        compare(media.checked, true);
    }

    // A desktop widget's placement sits beside its switch: one segmented
    // choice for the row (top, center, bottom) and one for the column.
    function placementOf(row) {
        return all(row.parent, child => child.vertical !== undefined && child.horizontal !== undefined)[0];
    }

    function test_placementShowsWhereTheDesktopWidgetIsAndChoosingMovesIt() {
        const built = make();
        const placement = placementOf(switchRow(built.item, "Weather"));

        verify(placement);
        compare(placement.vertical.value, "top");
        compare(placement.horizontal.value, "center");

        placement.vertical.chosen("bottom");
        compare(widgetsOf(built).weather.position, "bottom-center");

        placement.horizontal.chosen("right");
        compare(widgetsOf(built).weather.position, "bottom-right");

        placement.vertical.chosen("center");
        compare(widgetsOf(built).weather.position, "center-right");

        placement.horizontal.chosen("center");
        compare(widgetsOf(built).weather.position, "center");
        compare(placement.vertical.value, "center");
        compare(placement.horizontal.value, "center");
    }

    // Each placement is named after its desktop widget, so the choices don't
    // stand alone.
    function test_eachPlacementIsLabelledWithItsDesktopWidget() {
        const built = make();

        compare(placementOf(switchRow(built.item, "Background clock")).label, "Clock position");
        compare(placementOf(switchRow(built.item, "Media")).label, "Media position");
        compare(placementOf(switchRow(built.item, "Weather")).label, "Weather position");
        verify(textShown(built.item, "Clock position"));
    }

    function sameLine(item, first, second) {
        const a = first.mapToItem(item, 0, 0);
        const b = second.mapToItem(item, 0, 0);
        return a.y === b.y && a.x < b.x;
    }

    function test_theBackgroundClockIsTurnedOffWithASwitchRowAndPlacedBesideIt() {
        const built = make();
        const clock = switchRow(built.item, "Background clock");
        const placement = placementOf(clock);

        verify(clock);
        compare(clock.checked, true);
        verify(sameLine(built.item, clock, placement));

        clock.toggled();
        compare(widgetsOf(built).backgroundClock.enabled, false);

        placement.vertical.chosen("top");
        compare(widgetsOf(built).backgroundClock.position, "top-center");
    }

    function test_theClockSizeAndOpacitySitTwoPerLineAndStillSave() {
        const built = make();
        const size = numberCell(built.item, "Clock size");
        const opacity = numberCell(built.item, "Clock opacity");

        verify(size);
        verify(opacity);
        verify(sameLine(built.item, size, opacity));
        compare(size.value, 96);

        size.field.forceActiveFocus();
        size.field.selectAll();
        keyClick("1");
        keyClick("2");
        keyClick("0");
        keyClick(Qt.Key_Return);
        compare(widgetsOf(built).backgroundClock.size, 120);

        opacity.slider.forceActiveFocus();
        keyClick(Qt.Key_Left);
        compare(widgetsOf(built).backgroundClock.opacity, 99);
    }

    function test_theClockCalendarAndDateFormatSitTwoPerLineAndStillSave() {
        const built = make();
        const calendar = switchRow(built.item, "Clock calendar");
        const dateFormat = all(built.item, child => child.chosen !== undefined && child.options !== undefined
            && child.options.some(option => option.value === "numeric"))[0];

        verify(calendar);
        verify(dateFormat);
        // The choice sits under its label, in the cell beside the switch.
        verify(sameLine(built.item, calendar, dateFormat.parent));
        compare(dateFormat.value, "full");

        calendar.toggled();
        compare(widgetsOf(built).backgroundClock.calendarEnabled, true);

        dateFormat.chosen("none");
        compare(widgetsOf(built).backgroundClock.dateFormat, "none");
        compare(dateFormat.value, "none");
    }

    function test_theWeatherLocationSitsWithTheWeatherWidgetAndStillSaves() {
        const built = make();
        const weather = switchRow(built.item, "Weather");
        const location = all(weather.parent, child => child instanceof TextInput)[0];

        verify(location);
        compare(location.text, "Ourense, ES");

        location.forceActiveFocus();
        location.selectAll();
        keyClick("V");
        keyClick("i");
        keyClick("g");
        keyClick("o");
        keyClick(" ");
        keyClick(Qt.Key_Return);
        compare(widgetsOf(built).weather.location, "Vigo");
    }

    function buttons(item, label) {
        return all(item, child => child.label === label && child.activated !== undefined);
    }

    function textShown(item, text) {
        return all(item, child => child.text === text && child.font !== undefined
            && !(child instanceof TextInput)).length > 0;
    }

    function test_theStackOrderListsTheDesktopWidgetsAndQuietButtonsMoveThem() {
        const built = make();
        const up = buttons(built.item, "󰁝");
        const down = buttons(built.item, "󰁅");

        compare(up.length, 6);
        compare(down.length, 6);
        verify(textShown(built.item, "1. Media"));
        verify(!up[0].enabled, "the first can't move up");
        verify(!down[5].enabled, "the last can't move down");

        down[0].activated();

        compare(built.monitors.desktopWidgetOrder("DELL U2720Q"),
            ["system", "media", "calendar", "network", "weather", "cava"]);
        verify(textShown(built.item, "1. System"));
        verify(textShown(built.item, "2. Media"));
    }

    function test_noFilledCardsOrBoldTextRemain() {
        const built = make();
        const bold = all(built.item, child => child.font !== undefined && child.font.bold);
        // A slider's thin track keeps its fill; a card is a row-sized block.
        const filled = all(built.item, child => child.radius !== undefined && child.border !== undefined
            && child.height > 20 && child.color === theme.backgroundSecondary);

        compare(bold.length, 0);
        compare(filled.length, 0);
    }

    function test_theCavaWidgetHasItsSizeBarsColorAndShadow() {
        const built = make();
        const width = numberCell(built.item, "Cava width");
        const bars = numberCell(built.item, "Cava bars");
        const color = all(built.item, child => child.options !== undefined && child.chosen !== undefined
            && child.options.length === 9)[0];
        const shadow = switchRow(built.item, "Cava shadow");

        verify(width);
        verify(numberCell(built.item, "Cava height"));
        compare(bars.value, 32);
        compare(color.value, "white");
        compare(color.options.map(option => option.value)[0], "white");
        compare(shadow.checked, true);

        width.field.forceActiveFocus();
        width.field.selectAll();
        keyClick("5");
        keyClick("0");
        keyClick("0");
        keyClick(Qt.Key_Return);
        color.chosen("accent");
        shadow.toggled();

        compare(widgetsOf(built).cava.width, 500);
        compare(widgetsOf(built).cava.color, "accent");
        compare(widgetsOf(built).cava.shadow, false);
    }

    function test_onlyTheCavaWidgetShowsTheCavaSettings() {
        const built = make();
        const media = switchRow(built.item, "Media");

        compare(all(media.parent, child => child.label === "Cava width" && child.visible).length, 0);
    }

    // Every widget's grid builds the Cava rows hidden; the Cava grid is last.
    function field(item, label) {
        const found = all(item, child => child.label === label && child.small !== undefined);
        return found[found.length - 1];
    }

    function test_theCavaWidgetHasMediaInfoAndAProgressStyle() {
        const built = make();
        const info = switchRow(built.item, "Cava media info");
        const progress = all(field(built.item, "Cava progress"),
            child => child.options !== undefined && child.chosen !== undefined)[0];

        compare(info.checked, false);
        compare(progress.value, "off");
        compare(progress.options.map(option => option.label), ["Off", "Line", "Bars"]);

        info.toggled();
        progress.chosen("bars");

        compare(widgetsOf(built).cava.mediaInfo, true);
        compare(widgetsOf(built).cava.progress, "bars");
    }

    function test_theProgressColorOnlyShowsWithAProgressStyle() {
        const built = make();
        const color = field(built.item, "Cava progress color");
        const chooser = all(color, child => child.options !== undefined && child.chosen !== undefined)[0];

        verify(!color.visible);

        built.monitors.setDesktopWidgetSetting("DELL U2720Q", "cava", "progress", "line");
        verify(color.visible);
        compare(chooser.value, "accent");

        chooser.chosen("red");
        compare(widgetsOf(built).cava.progressColor, "red");
    }

    function test_everySettingOfTheSectionHasAnIcon() {
        const built = make();
        const named = all(built.item, child => child.icon !== undefined && child.label !== undefined
            && child.label !== "");

        verify(named.length > 20);
        compare(named.filter(child => child.icon === "").map(child => child.label), []);
    }

    function test_theEdgePaddingIsSetForTheWholeMonitor() {
        const built = make();
        const padding = numberCell(built.item, "Edge padding");

        compare(padding.value, 28);
        padding.edited(60);

        compare(widgetsOf(built).edgePadding, 60);
        compare(padding.value, 60);
    }
}
