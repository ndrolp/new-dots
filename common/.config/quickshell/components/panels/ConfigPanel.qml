import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../config" as Config

Rectangle {
    id: root

    required property var appearance
    required property var monitors
    required property var wallpapers
    required property var bookmarks
    required property var plugins
    // The shell's cava, so the Bar section can say when it can't run.
    property var cava
    property var monitorSetups

    property string currentSection: "Bar"
    property string pendingSection: ""
    property string wallpaperView: "Selection"
    property string selectedWallpaperMonitor: ""
    property string sectionQuery: ""
    readonly property var sections: [
        {
            // Old section names and terms stay as keywords so searches still land here.
            label: "Bar", icon: "󰔉", section: "Bar",
            keywords: "bar appearance bar widgets profile duplicate delete save discard density preset compact balanced spacious size spacing height padding style transparent opacity island docked pills group radius join elements data modules widgets order zone arch workspaces system monitor current app notifications badge battery clock media audio network tray bluetooth recording groups capsule edge margin border thickness icon",
            title: "Bar",
            description: "Edit a bar profile: its sizes, style and elements."
        },
        {
            label: "Notifications", icon: "󰂚", section: "Notifications",
            keywords: "notification popup location position",
            title: "Notifications",
            description: "Choose where notification popups appear."
        },
        {
            label: "Control center", icon: "󰒓", section: "ControlCenter",
            keywords: "tiles quick settings order collapsed row expanded hide show",
            title: "Control center",
            description: "Choose the control center's tiles and their order."
        },
        {
            label: "Motion", icon: "󰑮", section: "Motion",
            keywords: "animations reduce motion speed instant",
            title: "Motion",
            description: "Choose how the shell animates."
        },
        {
            label: "Displays", icon: "󰍹", section: "Monitors",
            keywords: "monitor screen workspace range bar profile",
            title: "Displays",
            description: "Set workspace ranges and shell visibility for each monitor."
        },
        {
            label: "Workspace Labels", icon: "󰌌", section: "Labels",
            keywords: "workspace names icons",
            title: "Workspace Labels",
            description: "Choose labels for workspaces 1 through 20."
        },
        {
            label: "Quick Search", icon: "󰍉", section: "Bookmarks",
            keywords: "bookmarks links search engines",
            title: "Quick Search",
            description: "Manage quick-search bookmarks and search engines."
        },
        {
            label: "Plugins", icon: "󰏗", section: "Plugins",
            keywords: "launcher clipboard search command capture control center",
            title: "Plugins",
            description: "Enable shell integrations and tune their behavior."
        },
        {
            label: "Desktop Widgets", icon: "󰖕", section: "Widgets",
            keywords: "media calendar system network weather background clock monitor",
            title: "Desktop Widgets",
            description: "Enable desktop widgets and choose their placement."
        },
        {
            label: "Session", icon: "󰌾", section: "Session",
            keywords: "idle lock power",
            title: "Session",
            description: "Control the active session and review idle behavior."
        },
        {
            label: "Wallpapers", icon: "󰸉", section: "Wallpapers",
            keywords: "background image monitor",
            title: "Wallpapers",
            description: "Choose a wallpaper for each display."
        }
    ]
    readonly property var currentEntry: sections.find(entry => entry.section === currentSection)
        || sections[sections.length - 1]
    readonly property var filteredSections: {
        const query = sectionQuery.trim().toLowerCase();
        return sections.filter(section => query === ""
            || (section.label + " " + section.keywords).toLowerCase().includes(query));
    }

    // What it shows, as another panel takes it (restoreView): its section,
    // search text, scroll position and Wallpapers view. The settings panel
    // keeps it across moves between the centered position and a capsule.
    readonly property var view: ({
        section: currentSection,
        query: sectionQuery,
        scroll: sectionScroll.contentItem.contentY,
        wallpaperView: wallpaperView,
        selectedWallpaperMonitor: selectedWallpaperMonitor
    })

    signal closeRequested()

    // Shows `view` (another panel's `view`), without the transition.
    function restoreView(view) {
        if (!view || view.section === undefined)
            return;
        sectionQuery = view.query || "";
        wallpaperView = view.wallpaperView || wallpaperView;
        selectedWallpaperMonitor = view.selectedWallpaperMonitor || selectedWallpaperMonitor;
        openSection(view.section);
        sectionScroll.contentItem.contentY = view.scroll || 0;
    }

    function loadCurrentSection() {
        let source;
        let properties = { appearance: root.appearance };

        if (currentSection === "Bar") {
            source = "BarSettings.qml";
            properties.monitors = root.monitors;
            properties.cava = root.cava;
        } else if (currentSection === "Notifications") {
            source = "NotificationSettings.qml";
        } else if (currentSection === "ControlCenter") {
            source = "ControlCenterSettings.qml";
        } else if (currentSection === "Motion") {
            source = "MotionSettings.qml";
        } else if (currentSection === "Monitors") {
            source = "MonitorArrangeSettings.qml";
            properties.monitors = root.monitors;
            properties.monitorSetups = root.monitorSetups;
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

    // Shows `section` straight away, without the transition: the panel is
    // being opened at it (e.g. from the control center's pencil).
    function openSection(section) {
        sectionTransition.stop();
        sectionLoader.opacity = 1;
        if (section === currentSection)
            return;

        currentSection = section;
        loadCurrentSection();
    }

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

        RowLayout {
            width: parent.width
            spacing: 16

            ShellText {
                text: "Settings"
                color: theme.text
                font.pixelSize: 20
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
            }

            SettingsInput {
                Layout.preferredWidth: 244
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignTop
                appearance: root.appearance
                placeholderText: "Search settings"
                text: root.sectionQuery

                onTextEdited: root.sectionQuery = text
                onAccepted: {
                    if (root.filteredSections.length > 0)
                        root.selectSection(root.filteredSections[0].section);
                }
            }

            SettingsButton {
                Layout.alignment: Qt.AlignTop
                appearance: root.appearance
                label: "Done"
                onActivated: root.closeRequested()
            }
        }

        Row {
            width: parent.width
            height: parent.height - 46
            spacing: 16

            Flickable {
                objectName: "sectionSidebar"
                width: 180
                height: parent.height
                contentWidth: width
                contentHeight: sectionList.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Column {
                    id: sectionList

                    width: parent.width
                    spacing: 5

                    Repeater {
                        model: root.filteredSections

                        // The selected section has a fill, an accent bar on its left and
                        // accent text; the others are filled only while hovered.
                        delegate: SettingsRow {
                            id: sectionRow

                            required property var modelData
                            readonly property bool selected: root.currentSection === sectionRow.modelData.section

                            width: parent.width
                            height: 38
                            appearance: root.appearance
                            clickable: true
                            color: selected || hovered ? theme.surfaceHover : "transparent"

                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3
                                height: parent.height - 16
                                radius: width / 2
                                color: theme.accent
                                opacity: sectionRow.selected ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: root.appearance.motion.short
                                        easing.type: root.appearance.motion.easing
                                    }
                                }
                            }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                spacing: 10

                                ShellText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: sectionRow.modelData.icon
                                    color: sectionRow.selected ? theme.accent : theme.textMuted
                                    font.pixelSize: 16

                                    Behavior on color {
                                        ColorAnimation { duration: root.appearance.motion.short }
                                    }
                                }

                                ShellText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: sectionRow.modelData.label
                                    color: sectionRow.selected ? theme.accent : theme.text
                                    font.pixelSize: root.appearance.textSize

                                    Behavior on color {
                                        ColorAnimation { duration: root.appearance.motion.short }
                                    }
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

                    ShellText {
                        text: root.currentEntry.title
                        color: theme.text
                        font.pixelSize: 18
                        font.bold: true
                    }

                    ShellText {
                        text: root.currentEntry.description
                        color: theme.textMuted
                        font.pixelSize: root.appearance.textSize
                    }

                    ScrollView {
                        id: sectionScroll

                        objectName: "sectionScroll"
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
                            objectName: "sectionContent"

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
            duration: root.appearance.motion.brief
            easing.type: root.appearance.motion.easing
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
            duration: root.appearance.motion.medium
            easing.type: root.appearance.motion.easing
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
