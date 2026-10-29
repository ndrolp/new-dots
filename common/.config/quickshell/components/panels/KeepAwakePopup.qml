import QtQuick

// The keep-awake popup: keep-awake's on/off switch.
BarPopup {
    id: root

    required property var keepAwake

    popup: "keepAwake"
    implicitWidth: 320

    KeepAwakePopupBody {
        width: parent.width
        appearance: root.appearance
        keepAwake: root.keepAwake
    }
}
