import QtQuick
import "." as Panels

// The Bar section, one scroll of cards for the edited bar profile: Profile,
// Style, Bar, Groups, Elements and, on a capsule profile, Capsule.
Column {
    id: root

    required property var appearance
    property var monitors
    property var cava

    width: parent ? parent.width : 0
    spacing: 12

    BarProfileSelector {
        appearance: root.appearance
        monitors: root.monitors
    }

    BarSizeStyleSettings {
        appearance: root.appearance
    }

    BarElementsSettings {
        appearance: root.appearance
        elementHints: ({ "cava": root.cava ? root.cava.failureHint : "" })
    }

    // A capsule's own: new notifications show inside it instead of as toasts.
    // Hidden whole on a bar style that uses none of its settings.
    Panels.SettingsCard {
        visible: !capsuleSettings.empty
        appearance: root.appearance
        title: "Capsule"

        Panels.BarSettingsGrid {
            id: capsuleSettings

            appearance: root.appearance
            settings: [
                { label: "Capsule vertical padding", from: 0, to: 16, propertyName: "capsuleVerticalPadding" },
                { label: "Notifications in the capsule", propertyName: "capsuleNotifications" }
            ]
        }
    }
}
