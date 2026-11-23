import QtQuick

// The audio output selector inside a capsule (AudioSinkSelectorBody.qml),
// opened instead of the full-screen one on a monitor whose bar is a capsule.
// Built only while open: every bar has one.
BarPopup {
    id: root

    // The audio output selector module (modules/AudioOutputSelector.qml).
    required property var feature

    popup: "audioOutputs"
    popupWidth: 440

    Loader {
        width: parent.width
        height: item ? item.implicitHeight : 0
        active: root.open || root.reveal > 0

        sourceComponent: AudioSinkSelectorBody {
            appearance: root.appearance
            active: root.shown

            onCloseRequested: root.popups.popupClosed(root.popup)
            onSinkSelected: sink => root.feature.osd.showAudioOutput(sink)
        }
    }
}
