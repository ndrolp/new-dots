import QtQuick
import "." as Panels

// Global notification settings (not part of any bar profile).
Column {
    id: root

    property var appearance

    width: parent ? parent.width : 0
    spacing: 14

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Popups"
        topPadding: 4
    }

    Panels.SettingsField {
        width: parent.width
        appearance: root.appearance
        label: "Position"

        Panels.SettingsChoice {
            width: parent.width
            appearance: root.appearance
            options: [
                { label: "Top left", value: "top-left" },
                { label: "Top center", value: "top-center" },
                { label: "Top right", value: "top-right" },
                { label: "Bottom left", value: "bottom-left" },
                { label: "Bottom center", value: "bottom-center" },
                { label: "Bottom right", value: "bottom-right" }
            ]
            value: root.appearance.notificationPopupLocation
            onChosen: location => root.appearance.notificationPopupLocation = location
        }
    }
}
