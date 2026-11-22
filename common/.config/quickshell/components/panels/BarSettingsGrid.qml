import QtQuick
import "." as Panels

// Bar profile settings two per line, in the order given: each entry
// { label, propertyName } is a switch, or a number when it also has
// { from, to }. Each saves through `appearance.setBarSetting` under its key.
Panels.SettingsGrid {
    id: grid

    required property var appearance
    property var settings: []

    Repeater {
        model: grid.settings

        delegate: Loader {
            id: cell

            required property var modelData

            width: grid.cellWidth
            sourceComponent: modelData.from === undefined ? switchSetting : numberSetting

            Component {
                id: numberSetting

                Panels.SettingsNumber {
                    appearance: grid.appearance
                    label: cell.modelData.label
                    from: cell.modelData.from
                    to: cell.modelData.to
                    value: grid.appearance[cell.modelData.propertyName]
                    onEdited: number => grid.appearance.setBarSetting(cell.modelData.propertyName, number)
                }
            }

            Component {
                id: switchSetting

                Panels.SettingsSwitchRow {
                    appearance: grid.appearance
                    label: cell.modelData.label
                    checked: grid.appearance[cell.modelData.propertyName]
                    onToggled: grid.appearance.setBarSetting(cell.modelData.propertyName,
                        !grid.appearance[cell.modelData.propertyName])
                }
            }
        }
    }
}
