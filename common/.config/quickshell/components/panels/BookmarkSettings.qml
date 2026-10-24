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

    // A bookmark or search engine: a settings row. Its glyph and name share
    // the first line with the row's actions; the link, which runs long, has
    // the second line to itself. Each field has a small label over it.
    component LinkRow: Panels.SettingsRow {
        id: row

        required property string glyph
        required property string name
        required property string link
        required property string linkKey
        required property string linkLabel
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
        appearance: root.appearance

        Column {
            id: rowContent

            x: 8
            y: 8
            width: parent.width - 16
            spacing: 8

            Row {
                width: parent.width
                spacing: 8

                Panels.SettingsField {
                    width: 56
                    appearance: root.appearance
                    label: "Glyph"
                    small: true

                    Panels.SettingsInput {
                        readonly property string fieldName: "glyph"

                        width: parent.width
                        appearance: root.appearance
                        text: row.glyph
                        placeholderText: "󰖟"
                        maximumLength: 4
                        horizontalAlignment: TextInput.AlignHCenter
                        onEdited: text => row.edited(fieldName, text)
                    }
                }

                Panels.SettingsField {
                    width: parent.width - 56 - actions.width - parent.spacing * 2
                    appearance: root.appearance
                    label: "Label"
                    small: true

                    Panels.SettingsInput {
                        readonly property string fieldName: "label"

                        width: parent.width
                        appearance: root.appearance
                        text: row.name
                        placeholderText: "Name"
                        onEdited: text => row.edited(fieldName, text)
                    }
                }

                Row {
                    id: actions

                    anchors.bottom: parent.bottom

                    Panels.SettingsMoveButtons {
                        anchors.verticalCenter: parent.verticalCenter
                        appearance: root.appearance
                        canMoveUp: row.canMoveUp
                        canMoveDown: row.canMoveDown
                        onMovedUp: row.movedUp()
                        onMovedDown: row.movedDown()
                    }

                    Panels.SettingsButton {
                        appearance: root.appearance
                        label: "Delete"
                        labelColor: theme.red
                        enabled: row.canRemove
                        onActivated: row.removed()
                    }
                }
            }

            Panels.SettingsField {
                width: parent.width
                appearance: root.appearance
                label: row.linkLabel
                small: true

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
        text: "Configure the links shown in the Alt+G quick-search panel."
    }

    Column {
        width: parent.width
        spacing: 2

        Repeater {
            model: root.bookmarks.items

            delegate: LinkRow {
                required property var modelData
                required property int index

                glyph: modelData.glyph
                name: modelData.label
                link: modelData.url
                linkKey: "url"
                linkLabel: "URL"
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
        text: "Choose the fallback engine in quick search. Use %s where the query belongs."
    }

    Column {
        width: parent.width
        spacing: 2

        Repeater {
            model: root.bookmarks.searchEngines

            delegate: LinkRow {
                required property var modelData
                required property int index

                glyph: modelData.glyph
                name: modelData.label
                link: modelData.searchUrl
                linkKey: "searchUrl"
                linkLabel: "Search URL"
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
