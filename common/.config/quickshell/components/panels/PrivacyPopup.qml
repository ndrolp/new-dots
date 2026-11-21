import QtQuick

// The privacy indicator's popup: which apps use the microphone and a camera.
BarPopup {
    id: root

    required property var deviceCaptures

    popup: "privacy"
    popupWidth: 300

    PrivacyPopupBody {
        width: parent.width
        appearance: root.appearance
        deviceCaptures: root.deviceCaptures
    }
}
