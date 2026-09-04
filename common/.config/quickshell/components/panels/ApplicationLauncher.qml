import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import "../../config" as Config

Variants {
    id: root

    required property var appearance
    required property var launcherHistory
    property bool open: false

    signal closeRequested()

    model: Quickshell.screens

    delegate: PanelWindow {
        id: launcher

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor && monitor
            && Hyprland.focusedWorkspace.monitor.name === monitor.name
        property real reveal: root.open ? 1 : 0
        property string searchQuery: ""
        property string applicationView: "all"
        readonly property int gridColumns: 5

        Behavior on reveal {
            NumberAnimation {
                duration: 240
                easing.type: Easing.OutCubic
            }
        }

        property var filteredApplications: {
            const query = searchQuery.trim().toLowerCase();
            const applications = DesktopEntries.applications.values;

            return applications.map(application => {
                if (application.noDisplay)
                    return null;

                const searchable = (application.name + " " + application.genericName + " "
                    + application.comment + " " + application.keywords.join(" ")).toLowerCase();
                const matchScore = fuzzyScore(searchable, query);

                if (query !== "" && matchScore < 0)
                    return null;
                if (applicationView === "favorites"
                        && !root.launcherHistory.isFavorite(application.id))
                    return null;
                if (applicationView === "recent"
                        && root.launcherHistory.recentIndex(application.id) < 0)
                    return null;

                return { application: application, matchScore: matchScore };
            }).filter(match => match !== null).sort((first, second) => {
                const firstFavorite = root.launcherHistory.isFavorite(first.application.id);
                const secondFavorite = root.launcherHistory.isFavorite(second.application.id);
                const firstFavoriteIndex = root.launcherHistory.favoriteIndex(first.application.id);
                const secondFavoriteIndex = root.launcherHistory.favoriteIndex(second.application.id);
                const firstRecent = root.launcherHistory.recentIndex(first.application.id);
                const secondRecent = root.launcherHistory.recentIndex(second.application.id);

                if (firstFavorite !== secondFavorite)
                    return firstFavorite ? -1 : 1;
                if (firstFavorite && firstFavoriteIndex !== secondFavoriteIndex)
                    return firstFavoriteIndex - secondFavoriteIndex;
                if (query !== "" && first.matchScore !== second.matchScore)
                    return second.matchScore - first.matchScore;
                if (firstRecent !== secondRecent)
                    return firstRecent < 0 ? 1 : secondRecent < 0 ? -1 : firstRecent - secondRecent;
                return first.application.name.localeCompare(second.application.name);
            });
        }

        screen: modelData
        visible: reveal > 0 && focusedMonitor
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-application-launcher"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Config.Theme {
            id: theme
        }

        function close() {
            root.closeRequested();
        }

        function fuzzyScore(text, query) {
            if (query === "")
                return 0;

            let score = 0;
            let queryIndex = 0;
            let consecutive = 0;

            for (let index = 0; index < text.length && queryIndex < query.length; index++) {
                if (text[index] !== query[queryIndex]) {
                    consecutive = 0;
                    continue;
                }

                score += 10 + consecutive * 6;
                if (index === 0 || /[\s_-]/.test(text[index - 1]))
                    score += 8;
                consecutive++;
                queryIndex++;
            }

            return queryIndex === query.length ? score : -1;
        }

        function selectRelative(offset) {
            if (filteredApplications.length === 0)
                return;

            applicationList.currentIndex = (applicationList.currentIndex + offset
                + filteredApplications.length) % filteredApplications.length;
            applicationList.positionViewAtIndex(applicationList.currentIndex, GridView.Contain);
        }

        function launchCurrent() {
            if (!applicationList.currentItem)
                return;

            applicationList.currentItem.application.execute();
            root.launcherHistory.recordLaunch(applicationList.currentItem.application.id);
            close();
        }

        function moveCurrentFavorite(offset) {
            if (!applicationList.currentItem)
                return;

            root.launcherHistory.moveFavorite(
                applicationList.currentItem.application.id, offset
            );
        }

        function selectApplicationView(offset) {
            const views = ["all", "favorites", "recent"];
            const currentIndex = views.indexOf(applicationView);
            applicationView = views[(currentIndex + offset + views.length) % views.length];
            applicationList.currentIndex = 0;
        }

        function applicationCount(view) {
            return DesktopEntries.applications.values.filter(application => {
                if (application.noDisplay)
                    return false;
                if (view === "favorites")
                    return root.launcherHistory.isFavorite(application.id);
                if (view === "recent")
                    return root.launcherHistory.recentIndex(application.id) >= 0;
                return true;
            }).length;
        }

        function iconSource(application) {
            if (application.icon.startsWith("/"))
                return "file://" + application.icon;

            return "image://icon/" + (application.icon || "utilities-terminal")
                + "?fallback=utilities-terminal";
        }

        onVisibleChanged: {
            if (visible) {
                searchQuery = "";
                applicationView = "all";
                applicationList.currentIndex = 0;
                searchInput.forceActiveFocus();
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            MouseArea {
                onClicked: launcher.close()
            }
        }

        Rectangle {
            id: launcherCard

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -(1 - launcher.reveal) * (height + 32)
            width: Math.min(parent.width - 64, 700)
            height: Math.min(parent.height - 80, 580)
            radius: root.appearance.radius
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.78)
            border.color: theme.border
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                TextField {
                    id: searchInput

                    width: parent.width
                    height: 46
                    placeholderText: "Search applications"
                    placeholderTextColor: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.6)
                    color: theme.text
                    font.family: theme.fontFamily
                    font.pixelSize: root.appearance.textSize + 1
                    font.bold: true
                    leftPadding: 42
                    rightPadding: 14
                    selectByMouse: true
                    text: launcher.searchQuery

                    background: Rectangle {
                        radius: root.appearance.radius
                        color: Qt.rgba(theme.backgroundSecondary.r, theme.backgroundSecondary.g,
                            theme.backgroundSecondary.b, 0.7)
                        border.color: searchInput.activeFocus ? theme.accent : "transparent"
                        border.width: 1
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍉"
                        color: theme.textMuted
                        font.family: theme.fontFamily
                        font.pixelSize: 19
                    }

                    onTextEdited: {
                        launcher.searchQuery = text;
                        applicationList.currentIndex = 0;
                    }

                    Keys.onEscapePressed: launcher.close()
                    Keys.onDownPressed: launcher.selectRelative(launcher.gridColumns)
                    Keys.onUpPressed: launcher.selectRelative(-launcher.gridColumns)
                    Keys.onLeftPressed: launcher.selectRelative(-1)
                    Keys.onRightPressed: launcher.selectRelative(1)
                    Keys.onReturnPressed: launcher.launchCurrent()
                    Keys.onEnterPressed: launcher.launchCurrent()
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Tab) {
                            launcher.selectApplicationView(
                                event.modifiers & Qt.ShiftModifier ? -1 : 1
                            );
                            event.accepted = true;
                        } else if (event.modifiers & Qt.ControlModifier
                                && event.modifiers & Qt.ShiftModifier
                                && event.key === Qt.Key_H) {
                            launcher.moveCurrentFavorite(-1);
                            event.accepted = true;
                        } else if (event.modifiers & Qt.ControlModifier
                                && event.modifiers & Qt.ShiftModifier
                                && event.key === Qt.Key_L) {
                            launcher.moveCurrentFavorite(1);
                            event.accepted = true;
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: [
                            { label: "All", value: "all" },
                            { label: "Favorites", value: "favorites" },
                            { label: "Recent", value: "recent" }
                        ]

                        delegate: Rectangle {
                            required property var modelData

                            width: 104
                            height: 28
                            radius: root.appearance.radius
                            color: launcher.applicationView === modelData.value
                                ? theme.accent : theme.backgroundSecondary

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label + "  " + launcher.applicationCount(modelData.value)
                                color: launcher.applicationView === modelData.value
                                    ? theme.background : theme.textMuted
                                font.pixelSize: root.appearance.textSize - 2
                                font.bold: true
                            }

                            TapHandler {
                                onTapped: {
                                    launcher.applicationView = modelData.value;
                                    applicationList.currentIndex = 0;
                                }
                            }
                        }
                    }
                }

                GridView {
                    id: applicationList

                    width: parent.width
                    height: parent.height - searchInput.height - 28 - parent.spacing * 2
                    clip: true
                    cellWidth: width / launcher.gridColumns
                    cellHeight: 108
                    model: launcher.filteredApplications
                    currentIndex: 0
                    boundsBehavior: Flickable.StopAtBounds

                    add: Transition {
                        NumberAnimation {
                            properties: "opacity,scale"
                            from: 0
                            to: 1
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                    }

                    remove: Transition {
                        NumberAnimation {
                            properties: "opacity,scale"
                            to: 0
                            duration: 120
                            easing.type: Easing.InCubic
                        }
                    }

                    displaced: Transition {
                        NumberAnimation {
                            properties: "x,y"
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                    }

                    delegate: Rectangle {
                        id: applicationTile

                        required property var modelData
                        readonly property var application: modelData.application
                        readonly property bool selected: GridView.isCurrentItem

                        width: applicationList.cellWidth - 8
                        height: applicationList.cellHeight - 8
                        radius: root.appearance.radius
                        color: selected || rowHover.hovered ? theme.surfaceHover : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        HoverHandler {
                            id: rowHover
                        }

                        IconImage {
                            id: applicationIcon

                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 14
                            width: 36
                            height: 36
                            source: launcher.iconSource(applicationTile.application)
                            visible: status === Image.Ready
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 14
                            width: 36
                            height: 36
                            radius: root.appearance.radius
                            visible: applicationIcon.status !== Image.Ready
                            color: theme.backgroundSecondary

                            IconImage {
                                anchors.centerIn: parent
                                width: 20
                                height: 20
                                source: "image://icon/utilities-terminal"
                            }
                        }

                        Text {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: 8
                            anchors.rightMargin: 9
                            text: root.launcherHistory.isFavorite(applicationTile.application.id)
                                ? "󰓎" : "󰓏"
                            color: root.launcherHistory.isFavorite(applicationTile.application.id)
                                ? theme.accent : theme.textDisabled
                            font.pixelSize: 16

                            TapHandler {
                                onTapped: root.launcherHistory
                                    .toggleFavorite(applicationTile.application.id)
                            }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.top: applicationIcon.bottom
                            anchors.topMargin: 8
                            horizontalAlignment: Text.AlignHCenter
                            text: applicationTile.application.name
                            color: theme.text
                            elide: Text.ElideRight
                            font.family: theme.fontFamily
                            font.pixelSize: root.appearance.textSize
                            font.bold: true
                        }

                        TapHandler {
                            onTapped: {
                                applicationList.currentIndex = index;
                                launcher.launchCurrent();
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    visible: launcher.filteredApplications.length === 0
                    text: "No matching applications"
                    color: theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    font.family: theme.fontFamily
                    font.pixelSize: root.appearance.textSize
                    font.bold: true
                }

                Text {
                    width: parent.width
                    visible: launcher.applicationView === "favorites"
                    text: "Ctrl+Shift+H/L reorders the selected favorite"
                    color: theme.textDisabled
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: root.appearance.textSize - 3
                }
            }
        }
    }
}
