import QtQuick

// The application launcher inside a capsule (ApplicationLauncherBody.qml),
// opened instead of the full-screen one on a monitor whose bar is a capsule.
// Built only while open: every bar has one.
BarPopup {
    id: root

    // The application launcher module (modules/ApplicationLauncher.qml), which holds what it shows.
    required property var feature
    readonly property real bodyHeight: 480

    popup: "launcher"
    popupWidth: 640

    Loader {
        width: parent.width
        height: root.bodyHeight
        active: root.open || root.reveal > 0

        sourceComponent: ApplicationLauncherBody {
            appearance: root.appearance
            launcherHistory: root.feature.launcherHistory
            active: root.shown

            onCloseRequested: root.popups.popupClosed(root.popup)
        }
    }
}
