import QtQuick
import "." as Panels

// The Workspace Labels section: whether the workspaces bar element shows
// glyphs, and the glyph for each of workspaces 1-20.
Column {
    id: root

    required property var appearance
    readonly property var workspaceIds: [
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
        11, 12, 13, 14, 15, 16, 17, 18, 19, 20
    ]
    readonly property bool glyphsEnabled: appearance.barElementOption("workspaces", "glyphsEnabled")

    width: parent ? parent.width : 0
    spacing: 14

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Workspace labels"
        topPadding: 4
    }

    Panels.SettingsGrid {
        Panels.SettingsSwitchRow {
            width: parent.cellWidth
            appearance: root.appearance
            label: "Use workspace glyphs"
            checked: root.glyphsEnabled
            onToggled: root.appearance.setBarElementOption("workspaces", "glyphsEnabled", !root.glyphsEnabled)
        }
    }

    Panels.SettingsHint {
        width: parent.width
        appearance: root.appearance
        text: "Leave a glyph empty to show its workspace number."
    }

    // Glyphs are a few characters, so their fields are short, five per line.
    Grid {
        width: parent.width
        columns: 5
        columnSpacing: 16
        rowSpacing: 14

        Repeater {
            model: root.workspaceIds

            delegate: Panels.SettingsField {
                required property int modelData

                width: (parent.width - parent.columnSpacing * (parent.columns - 1)) / parent.columns
                appearance: root.appearance
                label: "Workspace " + modelData

                Panels.SettingsInput {
                    width: parent.width
                    appearance: root.appearance
                    text: root.appearance.barElementOption("workspaces", "glyphs")[modelData - 1] || ""
                    placeholderText: String(modelData)
                    maximumLength: 4

                    onEdited: text => {
                        const glyphs = root.appearance.barElementOption("workspaces", "glyphs").slice();
                        glyphs[modelData - 1] = text;
                        root.appearance.setBarElementOption("workspaces", "glyphs", glyphs);
                    }
                }
            }
        }
    }
}
