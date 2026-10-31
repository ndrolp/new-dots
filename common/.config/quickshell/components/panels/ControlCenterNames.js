.pragma library

// The control center's names, spelled once: its popup id (OpenPopup.js,
// the bell), its two stages, its subpages (`noSubpage` for none) and the
// panels its tiles ask the control center module to open in its place
// (`tileSettings`: the settings panel at its Control center section).
var controlCenter = Object.freeze({
    popup: "controlCenter",
    collapsed: "collapsed",
    expanded: "expanded",
    noSubpage: "",
    audioOutputs: "audioOutputs",
    clipboard: "clipboard",
    powerMenu: "powerMenu",
    screenCapture: "screenCapture",
    tileSettings: "tileSettings"
});
