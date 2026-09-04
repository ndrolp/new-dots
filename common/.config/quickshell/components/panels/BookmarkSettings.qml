import "../../config" as Config
import QtQuick

Column {
    id: root

    property var appearance
    property var bookmarks

    width: parent ? parent.width : 0
    spacing: 12

    Config.Theme {
        id: theme
    }

    Text {
        width: parent.width
        text: "QUICK SEARCH BOOKMARKS"
        color: theme.textMuted
        font.pixelSize: 11
        font.bold: true
    }

    Text {
        width: parent.width
        text: "Configure the links shown in the Alt+G quick-search panel."
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 2
        font.bold: true
    }

    Rectangle {
        id: addBookmarkButton

        width: parent.width
        height: 42
        radius: root.appearance.radius
        color: addHover.hovered ? theme.accentHover : theme.accent

        HoverHandler {
            id: addHover
        }

        Text {
            anchors.centerIn: parent
            text: "󰐕  ADD BOOKMARK"
            color: theme.background
            font.family: theme.fontFamily
            font.pixelSize: root.appearance.textSize - 1
            font.bold: true
        }

        TapHandler {
            onTapped: root.bookmarks.add()
        }

        Behavior on color {
            ColorAnimation {
                duration: 140
            }

        }

    }

    Repeater {
        model: root.bookmarks.items

        delegate: Rectangle {
            id: bookmarkCard

            required property var modelData
            required property int index

            width: parent.width
            height: 174
            radius: root.appearance.radius
            color: cardHover.hovered ? theme.surfaceHover : theme.backgroundSecondary
            border.color: theme.border
            border.width: 1

            HoverHandler {
                id: cardHover
            }

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 7

                Row {
                    width: parent.width
                    height: 24

                    Text {
                        width: parent.width - 104
                        anchors.verticalCenter: parent.verticalCenter
                        text: "BOOKMARK " + (index + 1)
                        color: theme.textMuted
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Rectangle {
                        width: 24
                        height: 24
                        radius: root.appearance.radius
                        color: moveUpHover.hovered ? theme.surface : "transparent"
                        opacity: index > 0 ? 1 : 0.35

                        HoverHandler {
                            id: moveUpHover
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰁝"
                            color: theme.text
                            font.family: theme.fontFamily
                            font.pixelSize: 14
                        }

                        TapHandler {
                            enabled: index > 0
                            onTapped: root.bookmarks.move(index, index - 1)
                        }

                    }

                    Rectangle {
                        width: 24
                        height: 24
                        radius: root.appearance.radius
                        color: moveDownHover.hovered ? theme.surface : "transparent"
                        opacity: index < root.bookmarks.items.length - 1 ? 1 : 0.35

                        HoverHandler {
                            id: moveDownHover
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰁅"
                            color: theme.text
                            font.family: theme.fontFamily
                            font.pixelSize: 14
                        }

                        TapHandler {
                            enabled: index < root.bookmarks.items.length - 1
                            onTapped: root.bookmarks.move(index, index + 1)
                        }

                    }

                    Rectangle {
                        width: 56
                        height: 24
                        radius: root.appearance.radius
                        color: deleteHover.hovered ? theme.red : "transparent"

                        HoverHandler {
                            id: deleteHover
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "DELETE"
                            color: deleteHover.hovered ? theme.background : theme.red
                            font.pixelSize: 9
                            font.bold: true
                        }

                        TapHandler {
                            onTapped: root.bookmarks.remove(index)
                        }

                    }

                }

                Text {
                    text: "LABEL"
                    color: theme.textMuted
                    font.pixelSize: 10
                    font.bold: true
                }

                SettingsInput {
                    width: parent.width
                    appearance: root.appearance
                    text: modelData.label
                    onTextEdited: root.bookmarks.update(index, "label", text)
                }

                Row {
                    width: parent.width
                    spacing: 8

                    Text {
                        width: 64
                        text: "GLYPH"
                        color: theme.textMuted
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Text {
                        width: parent.width - 72
                        text: "URL"
                        color: theme.textMuted
                        font.pixelSize: 10
                        font.bold: true
                    }

                }

                Row {
                    width: parent.width
                    spacing: 8

                    SettingsInput {
                        width: 64
                        appearance: root.appearance
                        text: modelData.glyph
                        maximumLength: 4
                        horizontalAlignment: TextInput.AlignHCenter
                        onTextEdited: root.bookmarks.update(index, "glyph", text)
                    }

                    SettingsInput {
                        width: parent.width - 72
                        appearance: root.appearance
                        text: modelData.url
                        placeholderText: "https://example.com"
                        onTextEdited: root.bookmarks.update(index, "url", text)
                    }

                }

            }

            Behavior on color {
                ColorAnimation {
                    duration: 140
                }

            }

        }

    }

    Text {
        width: parent.width
        text: "SEARCH ENGINES"
        color: theme.textMuted
        font.pixelSize: 11
        font.bold: true
    }

    Text {
        width: parent.width
        text: "Choose the fallback engine in quick search. Use %s where the query belongs."
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 2
        font.bold: true
        wrapMode: Text.WordWrap
    }

    Rectangle {
        id: addSearchEngineButton

        width: parent.width
        height: 42
        radius: root.appearance.radius
        color: addEngineHover.hovered ? theme.accentHover : theme.accent

        HoverHandler {
            id: addEngineHover
        }

        Text {
            anchors.centerIn: parent
            text: "󰐕  ADD SEARCH ENGINE"
            color: theme.background
            font.family: theme.fontFamily
            font.pixelSize: root.appearance.textSize - 1
            font.bold: true
        }

        TapHandler {
            onTapped: root.bookmarks.addSearchEngine()
        }

        Behavior on color {
            ColorAnimation {
                duration: 140
            }

        }

    }

    Repeater {
        model: root.bookmarks.searchEngines

        delegate: Rectangle {
            id: engineCard

            required property var modelData
            required property int index

            width: parent.width
            height: 174
            radius: root.appearance.radius
            color: engineCardHover.hovered ? theme.surfaceHover : theme.backgroundSecondary
            border.color: theme.border
            border.width: 1

            HoverHandler {
                id: engineCardHover
            }

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 7

                Row {
                    width: parent.width
                    height: 24

                    Text {
                        width: parent.width - 104
                        anchors.verticalCenter: parent.verticalCenter
                        text: "SEARCH ENGINE " + (index + 1)
                        color: theme.textMuted
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Rectangle {
                        width: 24
                        height: 24
                        radius: root.appearance.radius
                        color: engineMoveUpHover.hovered ? theme.surface : "transparent"
                        opacity: index > 0 ? 1 : 0.35

                        HoverHandler {
                            id: engineMoveUpHover
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰁝"
                            color: theme.text
                            font.family: theme.fontFamily
                            font.pixelSize: 14
                        }

                        TapHandler {
                            enabled: index > 0
                            onTapped: root.bookmarks.moveSearchEngine(index, index - 1)
                        }

                    }

                    Rectangle {
                        width: 24
                        height: 24
                        radius: root.appearance.radius
                        color: engineMoveDownHover.hovered ? theme.surface : "transparent"
                        opacity: index < root.bookmarks.searchEngines.length - 1 ? 1 : 0.35

                        HoverHandler {
                            id: engineMoveDownHover
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰁅"
                            color: theme.text
                            font.family: theme.fontFamily
                            font.pixelSize: 14
                        }

                        TapHandler {
                            enabled: index < root.bookmarks.searchEngines.length - 1
                            onTapped: root.bookmarks.moveSearchEngine(index, index + 1)
                        }

                    }

                    Rectangle {
                        width: 56
                        height: 24
                        radius: root.appearance.radius
                        color: engineDeleteHover.hovered ? theme.red : "transparent"
                        opacity: root.bookmarks.searchEngines.length > 1 ? 1 : 0.35

                        HoverHandler {
                            id: engineDeleteHover
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "DELETE"
                            color: engineDeleteHover.hovered ? theme.background : theme.red
                            font.pixelSize: 9
                            font.bold: true
                        }

                        TapHandler {
                            enabled: root.bookmarks.searchEngines.length > 1
                            onTapped: root.bookmarks.removeSearchEngine(index)
                        }

                    }

                }

                Text {
                    text: "LABEL"
                    color: theme.textMuted
                    font.pixelSize: 10
                    font.bold: true
                }

                SettingsInput {
                    width: parent.width
                    appearance: root.appearance
                    text: modelData.label
                    onTextEdited: root.bookmarks.updateSearchEngine(index, "label", text)
                }

                Row {
                    width: parent.width
                    spacing: 8

                    Text {
                        width: 64
                        text: "GLYPH"
                        color: theme.textMuted
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Text {
                        width: parent.width - 72
                        text: "SEARCH URL"
                        color: theme.textMuted
                        font.pixelSize: 10
                        font.bold: true
                    }

                }

                Row {
                    width: parent.width
                    spacing: 8

                    SettingsInput {
                        width: 64
                        appearance: root.appearance
                        text: modelData.glyph
                        maximumLength: 4
                        horizontalAlignment: TextInput.AlignHCenter
                        onTextEdited: root.bookmarks.updateSearchEngine(index, "glyph", text)
                    }

                    SettingsInput {
                        width: parent.width - 72
                        appearance: root.appearance
                        text: modelData.searchUrl
                        placeholderText: "https://example.com/search?q=%s"
                        onTextEdited: root.bookmarks.updateSearchEngine(index, "searchUrl", text)
                    }

                }

            }

            Behavior on color {
                ColorAnimation {
                    duration: 140
                }

            }

        }

    }

}
