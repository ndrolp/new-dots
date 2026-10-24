import QtQuick
import "." as Panels

// A whole-number setting between `from` and `to`: its label on top, then a
// slider and a small number field side by side on one line. Moving the slider
// or typing a number in range asks to save it; a number out of range is
// rejected. A setting with room past what the slider shows types up to
// `fieldTo` instead. Whoever owns the setting saves it and sets `value`.
Panels.SettingsField {
    id: cell

    property int from: 0
    property int to: 100
    property int fieldTo: to
    property int value: 0
    readonly property alias slider: numberSlider
    readonly property alias field: numberField
    signal edited(int value)

    Row {
        width: parent.width
        spacing: 12

        SettingsSlider {
            id: numberSlider

            width: parent.width - numberField.width - parent.spacing
            height: numberField.height
            from: cell.from
            to: cell.to
            stepSize: 1
            value: cell.value
            onMoved: cell.edited(Math.round(value))
        }

        SettingsInput {
            id: numberField

            width: 56
            appearance: cell.appearance
            horizontalAlignment: TextInput.AlignHCenter
            text: String(cell.value)
            validator: IntValidator {
                bottom: cell.from
                top: cell.fieldTo
            }
            onEdited: text => cell.edited(Number(text))
        }
    }
}
