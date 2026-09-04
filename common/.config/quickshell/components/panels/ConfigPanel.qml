import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import "../../config" as Config

Rectangle {
    id: root

    required property var appearance
    required property var monitors
    required property var wallpapers
    required property var bookmarks

    property string currentSection: "Appearance"
    property string wallpaperView: "Selection"
    property string selectedWallpaperMonitor: ""

    signal closeRequested()

    function loadCurrentSection() {
        let source;
        let properties = { appearance: root.appearance };

        if (currentSection === "Appearance") {
            source = "AppearanceSettings.qml";
        } else if (currentSection === "Monitors") {
            source = "WorkspaceSettings.qml";
            properties.monitors = root.monitors;
        } else if (currentSection === "Labels") {
            source = "WorkspaceLabelsSettings.qml";
        } else if (currentSection === "Bookmarks") {
            source = "BookmarkSettings.qml";
            properties.bookmarks = root.bookmarks;
        } else if (currentSection === "Widgets") {
            source = "DesktopWidgetsSettings.qml";
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
    onCurrentSectionChanged: loadCurrentSection()

    implicitWidth: 900
    implicitHeight: 500
    radius: appearance.radius
    color: theme.surface
    border.color: theme.border
    border.width: 1

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#73000000"
        shadowBlur: 0.65
        shadowVerticalOffset: 6
    }

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
                font.bold: true
            }

            Item {
                width: parent.width - title.implicitWidth - doneButton.width
                height: 1
            }

            Rectangle {
                id: doneButton

                width: 76
                height: 34
                radius: root.appearance.radius
                color: doneHover.hovered ? theme.accentHover : theme.accent

                Behavior on color {
                    ColorAnimation { duration: 140 }
                }

                HoverHandler {
                    id: doneHover
                }

                Text {
                    anchors.centerIn: parent
                    text: "Done"
                    color: theme.background
                    font.pixelSize: root.appearance.textSize
                    font.bold: true
                }

                TapHandler {
                    onTapped: root.closeRequested()
                }
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
                    model: [
                        { label: "Bar Appearance", icon: "󰔉", section: "Appearance" },
                        { label: "Displays", icon: "󰍹", section: "Monitors" },
                        { label: "Workspace Labels", icon: "󰌌", section: "Labels" },
                        { label: "Quick Search", icon: "󰍉", section: "Bookmarks" },
                        { label: "Desktop Widgets", icon: "󰖕", section: "Widgets" },
                        { label: "Session", icon: "󰌾", section: "Session" },
                        { label: "Wallpapers", icon: "󰸉", section: "Wallpapers" }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: parent.width
                        height: 44
                        radius: root.appearance.radius
                        color: root.currentSection === modelData.section || sectionHover.hovered
                            ? theme.surfaceHover : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 140 }
                        }

                        HoverHandler {
                            id: sectionHover
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            spacing: 10

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.icon
                                color: root.currentSection === modelData.section ? theme.accent : theme.textMuted
                                font.pixelSize: 16
                                font.bold: true
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: root.currentSection === modelData.section ? theme.text : theme.textMuted
                                font.pixelSize: root.appearance.textSize
                                font.bold: true
                            }
                        }

                        TapHandler {
                            onTapped: root.currentSection = modelData.section
                        }
                    }
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
                        text: root.currentSection === "Appearance" ? "Bar Appearance"
                            : root.currentSection === "Monitors" ? "Displays"
                                : root.currentSection === "Labels" ? "Workspace Labels"
                                    : root.currentSection === "Bookmarks" ? "Quick Search"
                                        : root.currentSection === "Widgets" ? "Desktop Widgets"
                                        : root.currentSection === "Session" ? "Session"
                                            : "Wallpapers"
                        color: theme.text
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Text {
                        text: root.currentSection === "Appearance" ? "Fine-tune the shell layout."
                            : root.currentSection === "Monitors"
                                ? "Set workspace ranges and shell visibility for each monitor."
                                : root.currentSection === "Labels"
                                    ? "Choose labels for workspaces 1 through 20."
                                    : root.currentSection === "Bookmarks"
                                        ? "Manage quick-search bookmarks and search engines."
                                    : root.currentSection === "Widgets"
                                        ? "Enable desktop widgets and choose their placement."
                                    : root.currentSection === "Session"
                                        ? "Control the active session and review idle behavior."
                                        : "Choose a wallpaper for each display."
                        color: theme.textMuted
                        font.pixelSize: root.appearance.textSize
                        font.bold: true
                    }

                    ScrollView {
                        id: pageScroll

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

                            width: pageScroll.availableWidth - 12
                            height: item ? item.implicitHeight : 0
                        }
                    }
                }
            }
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
