import QtQuick
import QtQuick.Controls
import "../../config" as Config

Rectangle {
    id: root

    required property var appearance
    required property var monitors
    required property var wallpapers
    required property var bookmarks
    required property var plugins

    property string currentSection: "Bar"
    property string pendingSection: ""
    property string wallpaperView: "Selection"
    property string selectedWallpaperMonitor: ""
    property string sectionQuery: ""
    readonly property var sections: [
        {
            // Old section names and terms stay as keywords so searches still land here.
            label: "Bar", icon: "󰔉", section: "Bar",
            keywords: "bar appearance bar widgets profile duplicate delete save discard density preset compact balanced spacious size spacing height padding style transparent opacity island docked pills group radius join elements data modules widgets order zone arch workspaces system monitor current app notifications badge battery clock media audio network tray bluetooth recording"
        },
        {
            label: "Notifications", icon: "󰂚", section: "Notifications",
            keywords: "notification popup location position"
        },
        {
            label: "Displays", icon: "󰍹", section: "Monitors",
            keywords: "monitor screen workspace range bar profile"
        },
        {
            label: "Workspace Labels", icon: "󰌌", section: "Labels",
            keywords: "workspace names icons"
        },
        {
            label: "Quick Search", icon: "󰍉", section: "Bookmarks",
            keywords: "bookmarks links search engines"
        },
        {
            label: "Plugins", icon: "󰏗", section: "Plugins",
            keywords: "launcher clipboard search command capture control center"
        },
        {
            label: "Desktop Widgets", icon: "󰖕", section: "Widgets",
            keywords: "media calendar system network weather background clock monitor"
        },
        {
            label: "Session", icon: "󰌾", section: "Session",
            keywords: "idle lock power"
        },
        {
            label: "Wallpapers", icon: "󰸉", section: "Wallpapers",
            keywords: "background image monitor"
        }
    ]
    readonly property var filteredSections: {
        const query = sectionQuery.trim().toLowerCase();
        return sections.filter(section => query === ""
            || (section.label + " " + section.keywords).toLowerCase().includes(query));
    }

    signal closeRequested()

    function loadCurrentSection() {
        let source;
        let properties = { appearance: root.appearance };

        if (currentSection === "Bar") {
            source = "BarSettings.qml";
            properties.monitors = root.monitors;
        } else if (currentSection === "Notifications") {
            source = "NotificationSettings.qml";
        } else if (currentSection === "Monitors") {
            source = "WorkspaceSettings.qml";
            properties.monitors = root.monitors;
        } else if (currentSection === "Labels") {
            source = "WorkspaceLabelsSettings.qml";
        } else if (currentSection === "Bookmarks") {
            source = "BookmarkSettings.qml";
            properties.bookmarks = root.bookmarks;
        } else if (currentSection === "Plugins") {
            source = "PluginSettings.qml";
            properties.plugins = root.plugins;
        } else if (currentSection === "Widgets") {
            source = "DesktopWidgetsSettings.qml";
            properties.monitors = root.monitors;
        } else if (currentSection === "Session") {
            source = "SessionSettings.qml";
        } else {
            source = "WallpaperSettings.qml";
            properties.monitors = root.monitors;
            properties.wallpapers = root.wallpapers;
            properties.wallpaperView = root.wallpaperView;
            properties.selectedWallpaperMonitor = root.selectedWallpaperMonitor;
        }

        sectionLoader.setSource(source, properties);
    }

    Component.onCompleted: loadCurrentSection()

    function selectSection(section) {
        if (section === currentSection || sectionTransition.running)
            return;

        pendingSection = section;
        sectionTransition.start();
    }

    implicitWidth: 980
    implicitHeight: 560
    radius: appearance.radius
    color: theme.surface
    border.color: theme.border
    border.width: 1

    Config.Theme {
        id: theme
    }

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        Row {
            width: parent.width

            Text {
                id: title

                text: "Settings"
                color: theme.text
                font.pixelSize: 20
            }

            Item {
                width: parent.width - title.implicitWidth - sectionSearch.width - doneButton.width - 16
                height: 1
            }

            SettingsInput {
                id: sectionSearch

                width: 244
                appearance: root.appearance
                placeholderText: "Search settings"
                text: root.sectionQuery

                onTextEdited: root.sectionQuery = text
                onAccepted: {
                    if (root.filteredSections.length > 0)
                        root.selectSection(root.filteredSections[0].section);
                }
            }

            Item {
                width: 16
                height: 1
            }

            SettingsButton {
                id: doneButton

                appearance: root.appearance
                label: "Done"
                onActivated: root.closeRequested()
            }
        }

        Row {
            width: parent.width
            height: parent.height - 46
            spacing: 16

            Column {
                width: 180
                spacing: 6

                Repeater {
                    model: root.filteredSections

                    // The selected section shows in the accent text; only hover fills a row.
                    delegate: SettingsRow {
                        id: sectionRow

                        required property var modelData
                        readonly property bool selected: root.currentSection === sectionRow.modelData.section

                        width: parent.width
                        height: 44
                        appearance: root.appearance

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            spacing: 10

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: sectionRow.modelData.icon
                                color: sectionRow.selected ? theme.accent : theme.textMuted
                                font.pixelSize: 16
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: sectionRow.modelData.label
                                color: sectionRow.selected ? theme.accent : theme.text
                                font.pixelSize: root.appearance.textSize
                            }
                        }

                        TapHandler {
                            onTapped: root.selectSection(sectionRow.modelData.section)
                        }
                    }
                }

                SettingsHint {
                    width: parent.width
                    visible: root.filteredSections.length === 0
                    appearance: root.appearance
                    text: "No settings match this search."
                }
            }

            Rectangle {
                width: 1
                height: parent.height
                color: theme.border
            }

            Item {
                width: parent.width - 197
                height: parent.height

                Column {
                    anchors.fill: parent
                    spacing: 8

                    Text {
                        text: root.currentSection === "Bar" ? "Bar"
                            : root.currentSection === "Notifications" ? "Notifications"
                            : root.currentSection === "Monitors" ? "Displays"
                                : root.currentSection === "Labels" ? "Workspace Labels"
                                    : root.currentSection === "Bookmarks" ? "Quick Search"
                                    : root.currentSection === "Plugins" ? "Plugins"
                                        : root.currentSection === "Widgets" ? "Desktop Widgets"
                                        : root.currentSection === "Session" ? "Session"
                                            : "Wallpapers"
                        color: theme.text
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Text {
                        text: root.currentSection === "Bar"
                            ? "Edit a bar profile: its sizes, style and elements."
                            : root.currentSection === "Notifications"
                                ? "Choose where notification popups appear."
                            : root.currentSection === "Monitors"
                                ? "Set workspace ranges and shell visibility for each monitor."
                                : root.currentSection === "Labels"
                                    ? "Choose labels for workspaces 1 through 20."
                                    : root.currentSection === "Bookmarks"
                                        ? "Manage quick-search bookmarks and search engines."
                                    : root.currentSection === "Plugins"
                                        ? "Enable shell integrations and tune their behavior."
                                    : root.currentSection === "Widgets"
                                        ? "Enable desktop widgets and choose their placement."
                                    : root.currentSection === "Session"
                                        ? "Control the active session and review idle behavior."
                                        : "Choose a wallpaper for each display."
                        color: theme.textMuted
                        font.pixelSize: root.appearance.textSize
                    }

                    ScrollView {
                        id: sectionScroll

                        width: parent.width
                        height: parent.height - 56
                        clip: true

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            width: 8

                            contentItem: Rectangle {
                                implicitWidth: 8
                                radius: 4
                                color: theme.accent
                            }
                        }

                        Loader {
                            id: sectionLoader

                            width: sectionScroll.availableWidth - 12
                            height: item ? item.implicitHeight : 0
                        }
                    }
                }
            }
        }
    }

    SequentialAnimation {
        id: sectionTransition

        NumberAnimation {
            target: sectionLoader
            property: "opacity"
            to: 0
            duration: 100
            easing.type: Easing.OutCubic
        }

        ScriptAction {
            script: {
                root.currentSection = root.pendingSection;
                root.loadCurrentSection();
            }
        }

        NumberAnimation {
            target: sectionLoader
            property: "opacity"
            to: 1
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    Connections {
        target: sectionLoader.item
        ignoreUnknownSignals: true

        function onWallpaperViewChanged() {
            root.wallpaperView = sectionLoader.item.wallpaperView;
        }

        function onSelectedWallpaperMonitorChanged() {
            root.selectedWallpaperMonitor = sectionLoader.item.selectedWallpaperMonitor;
        }
    }

}
