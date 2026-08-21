import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Qt.labs.folderlistmodel
import "../../config" as Config

Rectangle {
    id: root

    required property var appearance
    required property var monitors
    required property var wallpapers

    property string currentSection: "Appearance"
    property string wallpaperView: "Selection"
    property string selectedWallpaperMonitor: ""
    readonly property var connectedMonitors: Hyprland.monitors.values

    signal closeRequested()

    implicitWidth: 900
    implicitHeight: 500
    radius: root.appearance.radius
    color: theme.surface

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

    FolderListModel {
        id: horizontalWallpapers

        folder: root.wallpapers.horizontalFolder === ""
            ? "" : Qt.resolvedUrl(root.wallpapers.horizontalFolder)
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        showDirs: false
    }

    FolderListModel {
        id: verticalWallpapers

        folder: root.wallpapers.verticalFolder === ""
            ? "" : Qt.resolvedUrl(root.wallpapers.verticalFolder)
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        showDirs: false
    }

    function isPortraitMonitor(monitorDescription) {
        const hyprlandMonitors = Hyprland.monitors.values;

        for (let index = 0; index < hyprlandMonitors.length; index++) {
            const monitor = hyprlandMonitors[index];

            if (monitor.description === monitorDescription) {
                const transform = Number(monitor.lastIpcObject.transform);

                if (transform === 1 || transform === 3)
                    return true;

                if (transform === 0 || transform === 2)
                    return false;

                return monitor.height > monitor.width;
            }
        }

        return false;
    }

    function ensureWallpaperMonitor() {
        const monitorNames = connectedMonitorNames();

        if (monitorNames.indexOf(selectedWallpaperMonitor) === -1)
            selectedWallpaperMonitor = monitorNames.length > 0 ? monitorNames[0] : "";
    }

    function connectedMonitorNames() {
        const names = [];

        for (let index = 0; index < root.connectedMonitors.length; index++) {
            const monitor = root.connectedMonitors[index];

            if (monitor.description !== "")
                names.push(monitor.description);
        }

        return names;
    }

    onCurrentSectionChanged: {
        if (currentSection === "Wallpapers")
            ensureWallpaperMonitor();
    }

    component ThemedInput: TextField {
        id: control

        height: 36
        leftPadding: 12
        rightPadding: 12
        color: theme.text
        font.pixelSize: root.appearance.textSize
        font.bold: true
        selectByMouse: true

        background: Rectangle {
            radius: root.appearance.radius
            color: theme.backgroundSecondary
            border.color: control.activeFocus ? theme.accent : "transparent"
            border.width: 1
        }
    }

    Connections {
        target: Hyprland.monitors

        function onValuesChanged() {
            root.ensureWallpaperMonitor();
        }
    }

    component ThemedSlider: Slider {
        id: control

        background: Rectangle {
            x: control.leftPadding
            y: control.topPadding + (control.availableHeight - height) / 2
            width: control.availableWidth
            height: 4
            radius: 2
            color: theme.backgroundSecondary

            Rectangle {
                width: parent.width * control.visualPosition
                height: parent.height
                radius: parent.radius
                color: theme.accent
            }
        }

        handle: Rectangle {
            x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
            y: control.topPadding + (control.availableHeight - height) / 2
            width: 14
            height: 14
            radius: 7
            color: theme.accent
        }
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
                        { label: "Workspaces", icon: "󰍹", section: "Monitors" },
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
                            : root.currentSection === "Monitors" ? "Workspaces" : "Wallpapers"
                        color: theme.text
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Text {
                        text: root.currentSection === "Appearance" ? "Fine-tune the shell layout."
                            : root.currentSection === "Monitors"
                                ? "Set the visible workspace range for each monitor."
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

                        Item {
                            width: pageScroll.availableWidth - 12
                            implicitHeight: 650

                            Column {
                                id: appearancePage

                                width: parent.width
                                spacing: 12
                                visible: root.currentSection === "Appearance"

                                Repeater {
                                    model: [
                                        { label: "Bar height", from: 24, to: 56, propertyName: "barHeight" },
                                        { label: "Horizontal padding", from: 0, to: 48, propertyName: "horizontalPadding" },
                                        { label: "Pill vertical padding", from: 0, to: 8, propertyName: "pillVerticalPadding" },
                                        { label: "Workspace bar padding", from: 0, to: 10, propertyName: "workspacePadding" },
                                        { label: "Transparent bar top margin", from: 0, to: 32, propertyName: "transparentBarTopMargin" },
                                        { label: "Corner radius", from: 0, to: 24, propertyName: "radius" },
                                        { label: "Component spacing", from: 0, to: 24, propertyName: "spacing" }
                                    ]

                                    delegate: Column {
                                        required property var modelData

                                        width: parent.width
                                        spacing: 5

                                        Text {
                                            text: modelData.label.toUpperCase()
                                            color: theme.textMuted
                                            font.pixelSize: 11
                                            font.bold: true
                                        }

                                        ThemedInput {
                                            width: parent.width
                                            text: String(root.appearance[modelData.propertyName])
                                            validator: IntValidator {
                                                bottom: modelData.from
                                                top: modelData.to
                                            }
                                            onEditingFinished: root.appearance[modelData.propertyName] = Number(text)
                                        }

                                        ThemedSlider {
                                            width: parent.width
                                            from: modelData.from
                                            to: modelData.to
                                            stepSize: 1
                                            value: root.appearance[modelData.propertyName]
                                            onMoved: root.appearance[modelData.propertyName] = Math.round(value)
                                        }
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 44
                                    radius: root.appearance.radius
                                    color: transparencyHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

                                    Behavior on color {
                                        ColorAnimation { duration: 140 }
                                    }

                                    HoverHandler {
                                        id: transparencyHover
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "TRANSPARENT BAR"
                                        color: theme.text
                                        font.pixelSize: root.appearance.textSize - 1
                                        font.bold: true
                                    }

                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 48
                                        height: 28
                                        radius: root.appearance.radius
                                        color: root.appearance.barTransparent ? theme.accent : theme.surface

                                        Rectangle {
                                            x: root.appearance.barTransparent ? parent.width - width - 3 : 3
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 22
                                            height: 22
                                            radius: 11
                                            color: theme.text

                                            Behavior on x {
                                                NumberAnimation {
                                                    duration: 160
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }
                                    }

                                    TapHandler {
                                        onTapped: root.appearance.barTransparent = !root.appearance.barTransparent
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 44
                                    radius: root.appearance.radius
                                    color: pillsTransparencyHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

                                    Behavior on color {
                                        ColorAnimation { duration: 140 }
                                    }

                                    HoverHandler {
                                        id: pillsTransparencyHover
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "TRANSPARENT PILLS"
                                        color: theme.text
                                        font.pixelSize: root.appearance.textSize - 1
                                        font.bold: true
                                    }

                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 48
                                        height: 28
                                        radius: root.appearance.radius
                                        color: root.appearance.pillsTransparent ? theme.accent : theme.surface

                                        Rectangle {
                                            x: root.appearance.pillsTransparent ? parent.width - width - 3 : 3
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 22
                                            height: 22
                                            radius: 11
                                            color: theme.text

                                            Behavior on x {
                                                NumberAnimation {
                                                    duration: 160
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }
                                    }

                                    TapHandler {
                                        onTapped: root.appearance.pillsTransparent = !root.appearance.pillsTransparent
                                    }
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: 12
                                visible: root.currentSection === "Monitors"

                                Repeater {
                                    model: root.connectedMonitors

                                    delegate: Column {
                                        required property var modelData
                                        readonly property string monitorDescription: modelData.description

                                        width: parent.width
                                        spacing: 5
                                        visible: monitorDescription !== ""

                                        Text {
                                            width: parent.width
                                            text: monitorDescription.toUpperCase()
                                            color: theme.textMuted
                                            elide: Text.ElideRight
                                            font.pixelSize: 11
                                            font.bold: true
                                        }

                                        Row {
                                            width: parent.width
                                            spacing: 8

                                            ThemedInput {
                                                width: (parent.width - parent.spacing) / 2
                                                text: String(root.monitors.rangeFor(monitorDescription).from)
                                                validator: IntValidator { bottom: 1 }
                                                onEditingFinished: root.monitors.setRangeStart(monitorDescription, Number(text))
                                            }

                                            ThemedInput {
                                                width: (parent.width - parent.spacing) / 2
                                                text: String(root.monitors.rangeFor(monitorDescription).to)
                                                validator: IntValidator { bottom: 1 }
                                                onEditingFinished: root.monitors.setRangeEnd(monitorDescription, Number(text))
                                            }
                                        }
                                    }
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: 10
                                visible: root.currentSection === "Wallpapers"

                                Row {
                                    spacing: 6

                                    Repeater {
                                        model: ["Selection", "Locations"]

                                        delegate: Rectangle {
                                            required property string modelData

                                            width: viewLabel.implicitWidth + 20
                                            height: 30
                                            radius: root.appearance.radius
                                            color: root.wallpaperView === modelData
                                                ? theme.accent : viewHover.hovered
                                                    ? theme.surfaceHover : theme.backgroundSecondary

                                            Behavior on color {
                                                ColorAnimation { duration: 140 }
                                            }

                                            HoverHandler {
                                                id: viewHover
                                            }

                                            Text {
                                                id: viewLabel

                                                anchors.centerIn: parent
                                                text: modelData
                                                color: root.wallpaperView === modelData ? theme.background : theme.text
                                                font.pixelSize: root.appearance.textSize - 2
                                                font.bold: true
                                            }

                                            TapHandler {
                                                onTapped: root.wallpaperView = modelData
                                            }
                                        }
                                    }
                                }

                                Column {
                                    width: parent.width
                                    spacing: 8
                                    visible: root.wallpaperView === "Locations"

                                    Text {
                                        text: "WALLPAPER FOLDERS"
                                        color: theme.textMuted
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    ThemedInput {
                                        width: parent.width
                                        text: root.wallpapers.horizontalFolder
                                        placeholderText: "Horizontal wallpaper folder"
                                        onTextEdited: root.wallpapers.horizontalFolder = text
                                    }

                                    ThemedInput {
                                        width: parent.width
                                        text: root.wallpapers.verticalFolder
                                        placeholderText: "Vertical wallpaper folder"
                                        onTextEdited: root.wallpapers.verticalFolder = text
                                    }
                                }

                                Column {
                                    width: parent.width
                                    spacing: 10
                                    visible: root.wallpaperView === "Selection"

                                    Row {
                                        width: parent.width
                                        spacing: 6

                                        Repeater {
                                            model: root.connectedMonitors

                                            delegate: Rectangle {
                                                required property var modelData
                                                readonly property string monitorDescription: modelData.description

                                                width: tabLabel.implicitWidth + 20
                                                height: 30
                                                radius: root.appearance.radius
                                                visible: monitorDescription !== ""
                                                color: root.selectedWallpaperMonitor === monitorDescription
                                                    ? theme.accent : tabHover.hovered
                                                        ? theme.surfaceHover : theme.backgroundSecondary

                                                Behavior on color {
                                                    ColorAnimation { duration: 140 }
                                                }

                                                HoverHandler {
                                                    id: tabHover
                                                }

                                                Text {
                                                    id: tabLabel

                                                    anchors.centerIn: parent
                                                    text: root.isPortraitMonitor(monitorDescription)
                                                        ? "󰍹 " + monitorDescription : "󰍺 " + monitorDescription
                                                    color: root.selectedWallpaperMonitor === monitorDescription
                                                        ? theme.background : theme.text
                                                    font.pixelSize: root.appearance.textSize - 2
                                                    font.bold: true
                                                }

                                                TapHandler {
                                                    onTapped: root.selectedWallpaperMonitor = monitorDescription
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        text: root.selectedWallpaperMonitor === ""
                                            ? "No monitors configured"
                                            : root.isPortraitMonitor(root.selectedWallpaperMonitor)
                                                ? "VERTICAL WALLPAPERS" : "HORIZONTAL WALLPAPERS"
                                        color: theme.textMuted
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    GridView {
                                        id: wallpaperGrid

                                        readonly property bool portrait: root.selectedWallpaperMonitor !== ""
                                            && root.isPortraitMonitor(root.selectedWallpaperMonitor)

                                        width: parent.width
                                        height: 250
                                        cellWidth: 128
                                        cellHeight: 112
                                        clip: true
                                        interactive: true
                                        model: portrait ? verticalWallpapers : horizontalWallpapers

                                        delegate: Rectangle {
                                            id: wallpaperTile

                                            required property string fileName
                                            readonly property string wallpaperPath:
                                                (wallpaperGrid.portrait
                                                    ? root.wallpapers.verticalFolder
                                                    : root.wallpapers.horizontalFolder)
                                                + "/" + fileName

                                            width: wallpaperGrid.cellWidth - 8
                                            height: wallpaperGrid.cellHeight - 8
                                            radius: root.appearance.radius
                                            color: tileHover.hovered ? theme.surfaceHover : theme.backgroundSecondary
                                            border.color: root.wallpapers.pathFor(root.selectedWallpaperMonitor)
                                                === wallpaperPath ? theme.accent : "transparent"
                                            border.width: 2

                                            HoverHandler {
                                                id: tileHover
                                            }

                                            Image {
                                                anchors.fill: parent
                                                anchors.margins: 2
                                                source: "file://" + wallpaperTile.wallpaperPath
                                                fillMode: Image.PreserveAspectCrop
                                                asynchronous: true
                                            }

                                            Text {
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.bottom: parent.bottom
                                                anchors.margins: 6
                                                text: wallpaperTile.fileName
                                                color: theme.text
                                                elide: Text.ElideRight
                                                font.pixelSize: root.appearance.textSize - 3
                                                font.bold: true
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                preventStealing: true
                                                onClicked: root.wallpapers.setWallpaper(
                                                    root.selectedWallpaperMonitor, wallpaperTile.wallpaperPath)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
