import QtQuick
import "../../config" as Config
import "../../config/DesktopWidgetsModel.js" as DesktopWidgetsModel

// The media info of the Cava desktop widget: the cover, with the player's app
// icon as a badge on its corner, then ♪ title, 󰠃 artist and 󰀥 album. With no cover
// the app icon fills its square, and with no app icon either, a music note in
// the progress color does. While paused, the square darkens under a pause
// glyph. It is only to look at: nothing in it can be pressed.
Item {
    id: root

    required property var appearance
    property string title: ""
    property string artist: ""
    property string album: ""
    // The cover's URL and the app icon's image source; empty when unknown.
    property string coverSource: ""
    property string appIconSource: ""
    property bool paused: false
    // At most this wide; the text elides to fit.
    property real maxWidth: 360
    property color noteColor: theme.accent

    readonly property int coverSize: DesktopWidgetsModel.cavaCoverSize(appearance.textSize)
    readonly property bool hasCover: cover.status === Image.Ready
    readonly property bool hasAppIcon: appIcon.status === Image.Ready
    readonly property alias text: textColumn
    readonly property real textWidth: Math.max(titleText.implicitWidth, artistText.implicitWidth,
        albumText.visible ? albumText.implicitWidth : 0)

    implicitWidth: Math.min(maxWidth, coverSize + row.spacing + textWidth)
    implicitHeight: coverSize
    width: implicitWidth
    height: implicitHeight

    Config.Theme {
        id: theme
    }

    Row {
        id: row

        anchors.fill: parent
        spacing: 14

        Item {
            id: slot

            width: root.coverSize
            height: root.coverSize

            Rectangle {
                id: coverFrame

                anchors.fill: parent
                radius: Math.max(4, root.appearance.radius - 4)
                color: "transparent"
                clip: true

                Image {
                    id: cover

                    objectName: "cover"
                    anchors.fill: parent
                    visible: root.hasCover
                    source: root.coverSource
                    sourceSize.width: root.coverSize * 2
                    sourceSize.height: root.coverSize * 2
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                // Darkens the square while paused, under the pause glyph.
                Rectangle {
                    anchors.fill: parent
                    visible: root.paused
                    color: Qt.rgba(0, 0, 0, 0.45)
                }
            }

            // The app icon: a badge on the cover's corner, or the whole square
            // without a cover.
            Image {
                id: appIcon

                objectName: "appIcon"
                readonly property int badgeSize: Math.round(root.coverSize * 0.42)

                visible: root.hasAppIcon
                source: root.appIconSource
                width: root.hasCover ? badgeSize : root.coverSize
                height: width
                x: root.hasCover ? parent.width - width + 3 : 0
                y: root.hasCover ? parent.height - height + 3 : 0
                sourceSize.width: root.coverSize * 2
                sourceSize.height: root.coverSize * 2
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            ShellText {
                objectName: "noteGlyph"
                anchors.centerIn: parent
                visible: !root.hasCover && !root.hasAppIcon
                text: "󰎈"
                color: root.noteColor
                font.pixelSize: Math.round(root.coverSize * 0.7)
            }

            ShellText {
                objectName: "pauseGlyph"
                anchors.centerIn: parent
                visible: root.paused
                text: "󰏤"
                color: "#ffffff"
                font.pixelSize: Math.round(root.coverSize * 0.5)
            }
        }

        Column {
            id: textColumn

            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, root.width - root.coverSize - row.spacing)
            spacing: 4

            ShellText {
                id: titleText

                width: parent.width
                text: "♪  " + root.title
                color: theme.text
                elide: Text.ElideRight
                font.pixelSize: root.appearance.textSize + 6
                font.bold: true
            }

            ShellText {
                id: artistText

                width: parent.width
                visible: root.artist !== ""
                text: "󰠃  " + root.artist
                color: theme.textMuted
                elide: Text.ElideRight
                font.pixelSize: root.appearance.textSize + 1
            }

            ShellText {
                id: albumText

                width: parent.width
                visible: root.album !== ""
                text: "󰀥  " + root.album
                color: theme.textMuted
                elide: Text.ElideRight
                font.pixelSize: root.appearance.textSize + 1
            }
        }
    }
}
