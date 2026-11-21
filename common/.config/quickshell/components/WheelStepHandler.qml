import QtQuick
import "WheelSteps.js" as WheelSteps

// Takes the wheel over its parent and tells each step it makes
// (WheelSteps.js): a mouse wheel one per notch, a touchpad gesture at most
// one. Scrolling down steps forward (1), up back (-1).
WheelHandler {
    id: root

    // The scroll so far, between events.
    property var scroll: WheelSteps.start()

    signal stepped(int step)

    target: null
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

    onWheel: event => {
        const result = WheelSteps.next(root.scroll, {
            angleDelta: event.angleDelta.y,
            pixelDelta: event.pixelDelta.y,
            phase: event.phase,
            time: Date.now()
        });
        root.scroll = result.state;
        if (result.step !== 0)
            root.stepped(result.step);
    }
}
