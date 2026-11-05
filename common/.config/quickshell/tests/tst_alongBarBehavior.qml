import QtQuick
import QtTest
import "../components/bar" as Bar

// What runs along the bar animates; across it, it follows the bar at once.
TestCase {
    name: "AlongBarBehavior"

    QtObject {
        id: profile

        property string barPosition: "top"
        property var motion: ({ medium: 100000, long: 100000, easing: 0 })
    }

    Component {
        id: element

        Item {
            Bar.AlongBarBehavior on x { appearance: profile }
            Bar.AlongBarBehavior on y { appearance: profile }
            Bar.AlongBarBehavior on width { appearance: profile; duration: profile.motion.long }
            Bar.AlongBarBehavior on height { appearance: profile; duration: profile.motion.long }
        }
    }

    function test_onlyWhatRunsAlongTheBarAnimates_data() {
        return [
            { tag: "top, x", position: "top", property: "x", animated: true },
            { tag: "top, width", position: "top", property: "width", animated: true },
            { tag: "top, y", position: "top", property: "y", animated: false },
            { tag: "top, height", position: "top", property: "height", animated: false },
            { tag: "bottom, x", position: "bottom", property: "x", animated: true },
            { tag: "bottom, height", position: "bottom", property: "height", animated: false },
            { tag: "left, y", position: "left", property: "y", animated: true },
            { tag: "left, height", position: "left", property: "height", animated: true },
            { tag: "left, x", position: "left", property: "x", animated: false },
            { tag: "left, width", position: "left", property: "width", animated: false },
            { tag: "right, y", position: "right", property: "y", animated: true },
            { tag: "right, width", position: "right", property: "width", animated: false }
        ];
    }

    function test_onlyWhatRunsAlongTheBarAnimates(data) {
        profile.barPosition = data.position;

        const item = createTemporaryObject(element, this);

        item[data.property] = 100;
        compare(item[data.property] === 100, !data.animated);
    }
}
