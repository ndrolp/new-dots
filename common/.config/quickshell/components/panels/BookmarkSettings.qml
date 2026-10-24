import QtQuick
import "../../config" as Config
import "." as Panels

Column {
    id: root

    property var appearance
    property var bookmarks

    width: parent ? parent.width : 0
    spacing: 14

    Config.Theme {
        id: theme
    }

    // A bookmark or search engine: a full-width row, transparent until
    // hovered. Its glyph and name share the first line with the row's
    // actions; the link, which runs long, has the second line to itself.
    component LinkRow: Rectangle {
        id: row

        required property string rowKind
        required property string glyph
        required property string name
        required property string link
        required property string linkKey
        property string linkPlaceholder: ""
        property bool canMoveUp: true
        property bool canMoveDown: true
        property bool canRemove: true
        signal edited(string key, string value)
        signal movedUp()
        signal movedDown()
        signal removed()

        width: parent ? parent.width : 0
        height: rowContent.implicitHeight + 16
        radius: root.appearance.radius
        color: rowHover.hovered ? theme.surfaceHover : "transparent"

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        HoverHandler {
            id: rowHover
        }

        Column {
            id: rowContent

            x: 8
            y: 8
            width: parent.width - 16
            spacing: 8

            Row {
                width: parent.width
                spacing: 8

                Panels.SettingsInput {
                    readonly property string fieldName: "glyph"

                    width: 56
                    appearance: root.appearance
                    text: row.glyph
                    maximumLength: 4
                    horizontalAlignment: TextInput.AlignHCenter
                    onEdited: text => row.edited(fieldName, text)
                }

                Panels.SettingsInput {
                    readonly property string fieldName: "label"

                    width: parent.width - 56 - actions.width - parent.spacing * 2
                    appearance: root.appearance
                    text: row.name
                    placeholderText: "Name"
                    onEdited: text => row.edited(fieldName, text)
                }

                Row {
                    id: actions

                    Panels.SettingsButton {
                        appearance: root.appearance
                        label: "󰁝"
                        enabled: row.canMoveUp
                        opacity: enabled ? 1 : 0.35
                        onActivated: row.movedUp()
                    }

                    Panels.SettingsButton {
                        appearance: root.appearance
                        label: "󰁅"
                        enabled: row.canMoveDown
                        opacity: enabled ? 1 : 0.35
                        onActivated: row.movedDown()
                    }

                    Panels.SettingsButton {
                        appearance: root.appearance
                        label: "Remove"
                        labelColor: theme.red
                        enabled: row.canRemove
                        opacity: enabled ? 1 : 0.35
                        onActivated: row.removed()
                    }
                }
            }

            Panels.SettingsInput {
                readonly property string fieldName: row.linkKey

                width: parent.width
                appearance: root.appearance
                text: row.link
                placeholderText: row.linkPlaceholder
                onEdited: text => row.edited(fieldName, text)
            }
        }
    }

    Panels.SettingsHeading {
        width: parent.width
        appearance: root.appearance
        text: "Bookmarks"
        topPadding: 4
    }

    Panels.SettingsHint {
        width: parent.width
        appearance: root.appearance
        text: "The links shown in the Alt+G quick-search panel."
    }

    Column {
        width: parent.width
        spacing: 2

        Repeater {
            model: root.bookmarks.items

            delegate: LinkRow {
                required property var modelData
                required property int index

                rowKind: "bookmark"
                glyph: modelData.glyph
                name: modelData.label
                link: modelData.url
                linkKey: "url"
                linkPlaceholder: "https://example.com"
                canMoveUp: index > 0
                canMoveDown: index < root.bookmarks.items.length - 1
                onEdited: (key, value) => root.bookmarks.update(index, key, value)
                onMovedUp: root.bookmarks.move(index, index - 1)
                onMovedDown: root.bookmarks.move(index, index + 1)
                onRemoved: root.bookmarks.remove(index)
            }
        }
    }

    Panels.SettingsButton {
        appearance: root.appearance
        label: "󰐕  Add bookmark"
        labelColor: theme.accent
        onActivated: root.bookmarks.add()
    }

    Panels.SettingsHeading {
        width: parent.width
        appearance: root.appearance
        text: "Search engines"
        topPadding: 8
    }

    Panels.SettingsHint {
        width: parent.width
        appearance: root.appearance
        text: "The fallback engines in quick search. Use %s where the query belongs."
    }

    Column {
        width: parent.width
        spacing: 2

        Repeater {
            model: root.bookmarks.searchEngines

            delegate: LinkRow {
                required property var modelData
                required property int index

                rowKind: "searchEngine"
                glyph: modelData.glyph
                name: modelData.label
                link: modelData.searchUrl
                linkKey: "searchUrl"
                linkPlaceholder: "https://example.com/search?q=%s"
                canMoveUp: index > 0
                canMoveDown: index < root.bookmarks.searchEngines.length - 1
                // Quick search always needs an engine to fall back on.
                canRemove: root.bookmarks.searchEngines.length > 1
                onEdited: (key, value) => root.bookmarks.updateSearchEngine(index, key, value)
                onMovedUp: root.bookmarks.moveSearchEngine(index, index - 1)
                onMovedDown: root.bookmarks.moveSearchEngine(index, index + 1)
                onRemoved: root.bookmarks.removeSearchEngine(index)
            }
        }
    }

    Panels.SettingsButton {
        appearance: root.appearance
        label: "󰐕  Add search engine"
        labelColor: theme.accent
        onActivated: root.bookmarks.addSearchEngine()
    }
}
