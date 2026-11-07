import QtQuick
import QtQuick.Controls
import QtTest
import "../components/panels" as Panels

// The canvas where it really lives: inside a section that scrolls.
Item {
    id: scene

    width: 800
    height: 300

    ScrollView {
        id: scroll

        anchors.fill: parent
        clip: true

        Column {
            width: scroll.availableWidth

            Panels.MonitorArrangeCanvas {
                id: canvas

                width: parent.width
                appearance: ({ radius: 8, textSize: 14 })
                monitors: [
                    { id: "DP-3", number: 1, label: "AOC", x: 0, y: 0, width: 2560, height: 1440 },
                    { id: "DP-4", number: 2, label: "Philips", x: -1080, y: -240, width: 1080, height: 1920 }
                ]
            }

            Item {
                width: parent.width
                height: 2000
            }
        }
    }

    SignalSpy {
        id: drops

        target: canvas
        signalName: "dropped"
    }

    TestCase {
        name: "MonitorArrangeInScroll"
        when: windowShown

        function monitor(id) {
            for (let i = 0; i < canvas.children.length; i++) {
                if (canvas.children[i].monitorId === id)
                    return canvas.children[i];
            }
            return null;
        }

        function test_aDragThatDriftsDownIsStillADrag() {
            drops.clear();
            const philips = monitor("DP-4");
            const y = philips.height / 2;
            mousePress(philips, 10, y);
            for (let step = 1; step <= 30; step++)
                mouseMove(philips, 10 + step * 10, y + step * 2);
            mouseRelease(philips, 310, y + 60);
            compare(drops.count, 1);
            compare(scroll.contentItem.contentY, 0);
        }
    }
}
