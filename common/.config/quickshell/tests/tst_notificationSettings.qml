import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config" as Config

// The Notifications section, built from the settings parts: where
// notification popups appear is a segmented choice.
TestCase {
    name: "NotificationSettings"
    width: 800
    height: 600
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

    function textOf(item, text) {
        return all(item, child => child.text === text && child.font !== undefined
            && !(child instanceof TextInput))[0] || null;
    }

    function choice(item) {
        return all(item, child => child.options !== undefined && child.chosen !== undefined)[0];
    }

    // The settings panel's page: the section sizes itself to it. A fake
    // appearance stands in for the shell's.
    Component {
        id: page

        Item {
            property alias appearance: appearance
            property alias section: section

            width: 700

            QtObject {
                id: appearance

                property int radius: 12
                property int textSize: 13
                property string notificationPopupLocation: "top-right"
            }

            Panels.NotificationSettings {
                id: section

                appearance: appearance
            }
        }
    }

    function make() {
        const built = createTemporaryObject(page, this);
        return { appearance: built.appearance, item: built.section };
    }

    function test_theCurrentPopupPositionIsMarkedInASegmentedChoice() {
        const built = make();
        const position = choice(built.item);

        verify(position);
        compare(position.options.length, 6);
        compare(position.value, "top-right");
        compare(textOf(position, "Top right").color, theme.accent);
        compare(textOf(position, "Top left").color, theme.text);
    }

    function test_choosingAPositionMovesWhereNotificationPopupsAppear() {
        const built = make();

        choice(built.item).chosen("bottom-left");

        compare(built.appearance.notificationPopupLocation, "bottom-left");
    }

    function test_nothingIsBoldAndNoFilledCardsRemain() {
        const built = make();
        const bold = all(built.item, child => child.font !== undefined && child.font.bold);
        const cards = all(built.item, child => child.color !== undefined && child.radius !== undefined
            && Qt.colorEqual(child.color, theme.backgroundSecondary));

        compare(bold.length, 0);
        compare(cards.length, 0);
    }
}
