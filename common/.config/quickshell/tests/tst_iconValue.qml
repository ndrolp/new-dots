import QtQuick
import QtTest
import "../components/bar" as Bar

// An icon and its value can take a lead before the value, in its own dimmer
// colour, as the expanded capsule's clock shows its date before the time.
TestCase {
    name: "IconValue"
    width: 400
    height: 100
    visible: true
    when: windowShown

    Component {
        id: clock

        Rectangle {
            property alias content: content

            width: 400
            height: 40
            color: "#000000"

            Bar.IconValue {
                id: content

                appearance: ({ barPosition: "top" })
                iconVisible: false
                iconColor: "#ff0000"
                leadColor: "#0000ff"
                value: "14:32"
            }
        }
    }

    // Which of red (the value) and blue (the lead) is drawn anywhere in
    // columns `from` to `to` of `item`.
    function inks(item, from, to) {
        const image = grabImage(item);
        const found = { red: false, blue: false };
        for (let x = from; x < to; x++) {
            for (let y = 0; y < item.height; y++) {
                const pixel = image.pixel(x, y);
                found.red = found.red || pixel.r > 0.5;
                found.blue = found.blue || pixel.b > 0.5;
            }
        }
        return found;
    }

    // Without a lead it is just its value.
    function test_withoutALeadItShowsOnlyItsValue() {
        const built = createTemporaryObject(clock, this);

        compare(inks(built, 0, built.content.width), { red: true, blue: false });
    }

    // A lead comes before the value, in its own colour, and lengthens it.
    function test_aLeadIsDrawnBeforeTheValueInItsColour() {
        const built = createTemporaryObject(clock, this);
        const alone = built.content.width;

        built.content.lead = "Thu 26 Nov · ";

        tryVerify(() => built.content.width > alone, 1000, "longer with a lead");
        // Where the value starts, give or take the pixel they share.
        const leadEnd = built.content.width - alone;
        compare(inks(built, 0, Math.floor(leadEnd) - 1), { red: false, blue: true });
        compare(inks(built, Math.ceil(leadEnd) + 1, built.content.width), { red: true, blue: false });
    }
}
