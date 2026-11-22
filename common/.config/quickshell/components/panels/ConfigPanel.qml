import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../config" as Config
import "SettingsSearch.js" as SettingsSearch

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
    // The label of the setting to scroll to and flash once its section shows.
    property string pendingSetting: ""
    property string wallpaperView: "Selection"
    property string selectedWallpaperMonitor: ""
    property string sectionQuery: ""
    // The sections, in sidebar order. Each lists the settings the search
    // offers by label, `settings`, as they are labelled in the section; a
    // Bar setting not every bar style shows names its profile key, `key`
    // (BarProfileModel.barSettingShown). tst_settingsSearch checks each label
    // against the section, and that every labelled setting is listed.
    readonly property var sections: [
        {
            // Old section names and terms stay as keywords so searches still land here.
            label: "Bar", icon: "󰔉", section: "Bar",
            keywords: "bar appearance bar widgets profile duplicate delete save discard density preset compact balanced spacious size spacing height padding style transparent opacity island docked pills group radius join elements data modules widgets order zone arch workspaces system monitor current app notifications badge battery clock media audio network tray bluetooth recording groups capsule edge margin border thickness icon",
            title: "Bar",
            description: "Edit a bar profile: its sizes, style and elements.",
            settings: [
                { label: "Bar style" },
                { label: "Bar position" },
                { label: "Density preset" },
                { label: "Bar thickness", key: "barHeight" },
                { label: "Bar opacity", key: "barOpacity" },
                { label: "Corner radius", key: "radius" },
                { label: "Horizontal padding", key: "horizontalPadding" },
                { label: "Vertical padding", key: "elementVerticalPadding" },
                { label: "Bar border", key: "barBorder" },
                { label: "Edge margin", key: "transparentBarTopMargin" },
                { label: "Group radius", key: "groupRadius" },
                { label: "Group horizontal padding", key: "groupHorizontalPadding" },
                { label: "Group vertical padding", key: "groupVerticalPadding" },
                { label: "Group border", key: "groupBorder" },
                { label: "Icon size", key: "iconSize" },
                { label: "Pill vertical padding", key: "pillVerticalPadding" },
                { label: "Component spacing", key: "spacing" },
                { label: "Element border", key: "elementBorder" },
                { label: "Transparent pills", key: "pillsTransparent" },
                { label: "Capsule vertical padding", key: "capsuleVerticalPadding" },
                { label: "Notifications in the capsule", key: "capsuleNotifications" }
            ]
        },
        {
            label: "Notifications", icon: "󰂚", section: "Notifications",
            keywords: "notification popup location position",
            title: "Notifications",
            description: "Choose where notification popups appear.",
            settings: [{ label: "Notification location" }]
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
            description: "Choose how the shell animates.",
            settings: [{ label: "Reduce motion" }]
        },
        {
            label: "Displays", icon: "󰍹", section: "Monitors",
            keywords: "monitor screen workspace range bar profile",
            title: "Displays",
            description: "Set workspace ranges and shell visibility for each monitor.",
            settings: [
                { label: "First workspace" },
                { label: "Last workspace" },
                { label: "Show bar" },
                { label: "Bar profile" }
            ]
        },
        {
            label: "Workspace Labels", icon: "󰌌", section: "Labels",
            keywords: "workspace names icons",
            title: "Workspace Labels",
            description: "Choose labels for workspaces 1 through 20.",
            settings: [{ label: "Use workspace glyphs" }]
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
            description: "Enable shell integrations and tune their behavior.",
            settings: [
                { label: "Application launcher" },
                { label: "Clipboard history" },
                { label: "Quick search" },
                { label: "Unified search" },
                { label: "Quick settings" },
                { label: "Command launcher" },
                { label: "Screen capture" },
                { label: "Control center" },
                { label: "Web app maker" },
                { label: "Printers" },
                { label: "Android devices" },
                { label: "Launcher recent apps" },
                { label: "Clipboard image previews" }
            ]
        },
        {
            label: "Desktop Widgets", icon: "󰖕", section: "Widgets",
            keywords: "media calendar system network weather background clock monitor",
            title: "Desktop Widgets",
            description: "Enable desktop widgets and choose their placement.",
            settings: [
                { label: "Edge padding" },
                { label: "Background clock" },
                { label: "Clock position" },
                { label: "Clock size" },
                { label: "Clock opacity" },
                { label: "Clock calendar" },
                { label: "Date format" }
            ]
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
    // The sections the search finds, each with its matching settings.
    readonly property var filteredSections: SettingsSearch.search(sections, sectionQuery, appearance.barStyle)

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

    // Opens `section`, then scrolls the setting labelled `label` into view
    // and flashes it.
    function selectSetting(section, label) {
        if (sectionTransition.running)
            return;

        pendingSetting = label;
        if (section === currentSection)
            Qt.callLater(revealPendingSetting);
        else
            selectSection(section);
    }

    // Where Enter on the search goes: the first setting listed under the
    // first section found, or that section.
    function chooseFirstMatch() {
        const match = SettingsSearch.firstMatch(filteredSections);
        if (match === null)
            return;
        if (match.setting !== "")
            selectSetting(match.section, match.setting);
        else
            selectSection(match.section);
    }

    // The shown item labelled `label` inside `item`, or null.
    function findSetting(item, label) {
        if (!item.visible)
            return null;
        if (item.label === label)
            return item;
        for (let i = 0; i < item.children.length; i++) {
            const found = findSetting(item.children[i], label);
            if (found)
                return found;
        }
        return null;
    }

    // Scrolls the pending setting into the middle of the section's scroll
    // area, as far as the section scrolls, and flashes it.
    function revealPendingSetting() {
        const label = pendingSetting;
        pendingSetting = "";
        const setting = label !== "" && sectionLoader.item ? findSetting(sectionLoader.item, label) : null;
        if (!setting)
            return;

        const at = setting.mapToItem(sectionContent, 0, 0);
        const scroll = sectionScroll.contentItem;
        const room = sectionScroll.height;
        const top = at.y - Math.max(0, (room - setting.height) / 2);
        scroll.contentY = Math.max(0, Math.min(top, sectionContent.height - room));

        settingHighlight.x = at.x - 4;
        settingHighlight.y = at.y - 4;
        settingHighlight.width = setting.width + 8;
        settingHighlight.height = setting.height + 8;
        settingFlash.restart();
    }

    implicitWidth: 980
    implicitHeight: 560
    radius: appearance.radius
    // Translucent: centered, the blurred desktop shows through. Inside a
    // capsule the popup's surface replaces it (SettingsPopup.qml).
    color: theme.translucentSurface
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
                    root.chooseFirstMatch();
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

                        // A section's row, then a row for each of its settings the
                        // search found.
                        delegate: Column {
                            id: sectionEntry

                            required property var modelData

                            width: parent.width
                            spacing: 2

                            // The selected section has a fill, an accent bar on its left and
                            // accent text; the others are filled only while hovered.
                            SettingsRow {
                                id: sectionRow

                                readonly property var modelData: sectionEntry.modelData
                                readonly property bool selected: root.currentSection === sectionRow.modelData.section

                                width: parent.width
                                height: 38
                                appearance: root.appearance
                                clickable: true
                                color: selected || hovering ? theme.surfaceHover : "transparent"

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

                            // A found setting, indented under its section's label.
                            Repeater {
                                model: sectionEntry.modelData.settings

                                delegate: SettingsRow {
                                    id: settingRow

                                    required property var modelData

                                    width: parent.width
                                    height: Math.max(30, settingLabel.height + 12)
                                    appearance: root.appearance
                                    clickable: true

                                    ShellText {
                                        id: settingLabel

                                        anchors.left: parent.left
                                        anchors.leftMargin: 38
                                        anchors.right: parent.right
                                        anchors.rightMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: settingRow.modelData.label
                                        color: theme.textMuted
                                        wrapMode: Text.Wrap
                                        font.pixelSize: root.appearance.textSize - 1
                                    }

                                    TapHandler {
                                        onTapped: root.selectSetting(sectionEntry.modelData.section,
                                            settingRow.modelData.label)
                                    }
                                }
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

                        Item {
                            id: sectionContent

                            width: sectionScroll.availableWidth - 12
                            height: sectionLoader.height
                            implicitWidth: width
                            implicitHeight: height

                            Loader {
                                id: sectionLoader
                                objectName: "sectionContent"

                                width: parent.width
                                height: item ? item.implicitHeight : 0
                            }

                            // The accent flash over a setting the search went to:
                            // it comes up, holds a moment and fades away.
                            Rectangle {
                                id: settingHighlight

                                objectName: "settingHighlight"
                                radius: root.appearance.radius
                                color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.16)
                                border.color: theme.accent
                                border.width: 2
                                opacity: 0
                                visible: opacity > 0
                            }
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
                if (root.pendingSetting !== "")
                    Qt.callLater(root.revealPendingSetting);
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

    SequentialAnimation {
        id: settingFlash

        NumberAnimation {
            target: settingHighlight
            property: "opacity"
            from: 0
            to: 1
            duration: root.appearance.motion.short
            easing.type: root.appearance.motion.easing
        }

        // Held long enough to be seen, even with reduce motion's instant
        // fades: it is a pause, not a movement.
        PauseAnimation {
            duration: 700
        }

        NumberAnimation {
            target: settingHighlight
            property: "opacity"
            to: 0
            duration: root.appearance.motion.long
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
