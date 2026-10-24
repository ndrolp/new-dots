import QtQuick
import "../../config" as Config
import "." as Panels
import "AudioOutputs.js" as AudioOutputs

// An audio output's name in an output list: its label, in the accent when
// highlighted, over its muted port. `rowHeight` is the height of a row that
// fits it, taller when the port shows.
Column {
    id: outputName

    required property var appearance
    property var output: null
    property bool highlighted: false
    property int labelSize: appearance.textSize
    readonly property string port: AudioOutputs.port(output)
    readonly property int rowHeight: port !== "" ? 42 : 36

    Config.Theme {
        id: theme
    }

    Panels.Text {
        width: parent.width
        text: AudioOutputs.label(outputName.output)
        color: outputName.highlighted ? theme.accent : theme.text
        elide: Text.ElideRight
        font.pixelSize: outputName.labelSize
    }

    Panels.Text {
        width: parent.width
        visible: text !== ""
        text: outputName.port
        color: theme.textMuted
        elide: Text.ElideRight
        font.pixelSize: outputName.appearance.textSize - 3
    }
}
