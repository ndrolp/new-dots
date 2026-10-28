import Quickshell.Io
import QtQuick
import "NightLightState.js" as NightLightState

// Night light: hyprsunset warming the screen while it is on. The shell owns
// the one instance the control center drives. The temperature is saved in
// appearance.json; whether it is on isn't, so every shell start begins with it
// off. When it turns on and off is decided in NightLightState.js; this only
// carries it out.
QtObject {
    id: root

    required property var appearance

    readonly property bool on: state.on
    // Why night light went off on its own ("" otherwise).
    readonly property string failureHint: state.failureHint
    // The saved temperature, in kelvin (NightLightState.temperature).
    readonly property int temperature: NightLightState.temperature(appearance.nightLightTemperature)
    property var state: NightLightState.off

    function toggle() {
        follow(NightLightState.toggled(state));
    }

    // Saves `kelvin` as the temperature; a running hyprsunset follows it.
    function setTemperature(kelvin) {
        appearance.nightLightTemperature = NightLightState.temperature(kelvin);
    }

    // Moves to the `next` state and starts or stops hyprsunset to match it.
    function follow(next) {
        state = next;
        if (next.on && !hyprsunset.running)
            hyprsunset.command = NightLightState.startCommand(temperature);
        if (hyprsunset.running !== next.on)
            hyprsunset.running = next.on;
    }

    onTemperatureChanged: {
        if (hyprsunset.running)
            temperatureCommand.exec(NightLightState.temperatureCommand(temperature));
    }

    property var process: Process {
        id: hyprsunset

        onExited: exitCode => root.follow(NightLightState.exited(root.state, exitCode))
    }

    property var temperatureProcess: Process {
        id: temperatureCommand
    }
}
