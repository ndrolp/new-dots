import QtQuick

// A window's captured frame, laid over its icon and title. It stays out of the
// way until the frame arrives, which on a hidden workspace may be never: Hyprland
// doesn't refuse the capture, it just doesn't answer. `frame` is a ScreencopyView
// from WindowFrames.qml, which owns it, so this can be anywhere in the same window.
ShaderEffectSource {
    property Item frame: null

    visible: frame !== null && frame.hasContent
    sourceItem: frame
    // Only as sharp as it's shown, not the size of the window it came from.
    textureSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
}
