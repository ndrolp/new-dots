import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import "../../config" as Config
import "../IconSource.js" as IconSource
import "../../services/WebApps.js" as WebApps
import "." as Panels

// The web app maker's window: a small centred card on the focused monitor
// with the form that makes a web app from a URL, and the web apps it made.
// Everything it does goes through the web apps service.
Variants {
    id: root

    required property var appearance
    required property var webApps
    property bool open: false

    signal closeRequested()

    model: Quickshell.screens

    delegate: PanelWindow {
        id: maker

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor && monitor
            && Hyprland.focusedWorkspace.monitor.name === monitor.name
        // It steps aside while the icon file chooser is open, which would
        // otherwise sit under it.
        readonly property bool shown: root.open && focusedMonitor && !root.webApps.pickingIcon

        // What the form holds. The name and icon follow the probe until
        // they are edited or picked by hand.
        property string urlText: ""
        readonly property string url: WebApps.normalize(urlText)
        property string name: ""
        property bool nameEdited: false
        property string icon: ""
        property bool iconPicked: false
        readonly property var duplicate: url === "" ? null : WebApps.duplicateOf(root.webApps.apps, url)
        // The row whose delete is waiting for a confirmation.
        property string deleteArmed: ""
        readonly property string problem: !root.webApps.browserAvailable
            ? WebApps.browser + " isn't installed, so web apps can't be created."
            : urlText.trim() !== "" && url === ""
            ? "Not a web address. Only http and https sites can be web apps."
            : duplicate ? duplicate.name + " already opens this URL."
            : root.webApps.failure
        readonly property bool canCreate: url !== "" && !duplicate && name.trim() !== ""
            && root.webApps.browserAvailable && !root.webApps.creating

        screen: modelData
        visible: shown
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-web-app-maker"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        function reset() {
            urlText = "";
            name = "";
            nameEdited = false;
            icon = "";
            iconPicked = false;
            deleteArmed = "";
            root.webApps.failure = "";
            root.webApps.probe("");
        }

        function create() {
            if (canCreate)
                root.webApps.create(url, name.trim(), icon);
        }

        function openApp(app) {
            root.webApps.launch(app.url);
            root.closeRequested();
        }

        // Follows the probe for the current URL, unless edited by hand.
        function takeProbe() {
            if (url === "" || root.webApps.probedUrl !== url)
                return;
            if (!nameEdited)
                name = root.webApps.probedName;
            if (!iconPicked)
                icon = root.webApps.probedIcon;
        }

        onUrlChanged: {
            if (!nameEdited)
                name = url === "" ? "" : WebApps.fallbackName(url);
            if (!iconPicked)
                icon = "";
            probeDelay.restart();
            takeProbe();
        }

        onVisibleChanged: {
            if (visible && !root.webApps.pickingIcon) {
                root.webApps.refresh();
                urlField.forceActiveFocus();
            }
        }

        Connections {
            target: root

            function onOpenChanged() {
                if (root.open)
                    maker.reset();
            }
        }

        Connections {
            target: root.webApps

            function onProbedUrlChanged() {
                maker.takeProbe();
            }

            function onIconPicked(path) {
                maker.icon = path;
                maker.iconPicked = true;
            }

            function onPickingIconChanged() {
                if (!root.webApps.pickingIcon && maker.visible)
                    urlField.forceActiveFocus();
            }
        }

        Timer {
            id: probeDelay

            interval: 600
            onTriggered: root.webApps.probe(maker.url)
        }

        Config.Theme {
            id: theme
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            TapHandler {
                onTapped: root.closeRequested()
            }
        }

        Rectangle {
            id: card

            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 460)
            height: Math.min(parent.height - 80, content.implicitHeight + 32)
            radius: root.appearance.radius
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.78)
            border.color: theme.border
            border.width: 1

            // Clicks on the card don't reach the backdrop behind it.
            TapHandler {}

            Keys.onEscapePressed: root.closeRequested()

            Column {
                id: content

                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Panels.ShellText {
                    text: "New web app"
                    color: theme.text
                    font.pixelSize: root.appearance.textSize + 2
                    font.bold: true
                }

                Row {
                    width: parent.width
                    spacing: 12

                    // The icon: the site's, a picked image or the globe. Pressing it picks an image.
                    Rectangle {
                        id: iconButton

                        width: 64
                        height: 64
                        radius: root.appearance.radius
                        color: iconHover.hovered ? theme.surfaceHover : theme.backgroundSecondary
                        border.color: theme.border
                        border.width: 1

                        Image {
                            anchors.centerIn: parent
                            width: 44
                            height: 44
                            sourceSize.width: 88
                            sourceSize.height: 88
                            fillMode: Image.PreserveAspectFit
                            cache: false
                            source: maker.icon !== "" ? "file://" + maker.icon
                                : IconSource.forName(WebApps.fallbackIcon)
                        }

                        Panels.ShellText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                            visible: root.webApps.probing && !maker.iconPicked
                            text: "…"
                            color: theme.textMuted
                        }

                        HoverHandler {
                            id: iconHover
                        }

                        TapHandler {
                            onTapped: root.webApps.pickIcon()
                        }
                    }

                    Column {
                        width: parent.width - iconButton.width - parent.spacing
                        spacing: 8

                        Panels.PopupTextField {
                            id: urlField

                            width: parent.width
                            appearance: root.appearance
                            leftPadding: 10
                            placeholderText: "URL (youtube.com)"
                            text: maker.urlText
                            onTextEdited: maker.urlText = text
                            onAccepted: maker.create()
                            KeyNavigation.tab: nameField
                            Keys.onEscapePressed: root.closeRequested()
                        }

                        Panels.PopupTextField {
                            id: nameField

                            width: parent.width
                            appearance: root.appearance
                            leftPadding: 10
                            placeholderText: "Name"
                            text: maker.name
                            onTextEdited: {
                                maker.name = text;
                                maker.nameEdited = true;
                            }
                            onAccepted: maker.create()
                            KeyNavigation.tab: urlField
                            Keys.onEscapePressed: root.closeRequested()
                        }
                    }
                }

                Panels.ShellText {
                    width: parent.width
                    visible: maker.problem !== ""
                    text: maker.problem
                    wrapMode: Text.Wrap
                    color: maker.duplicate ? theme.textMuted : theme.red
                    font.pixelSize: root.appearance.textSize - 1
                }

                Row {
                    anchors.right: parent.right
                    spacing: 8

                    Panels.PopupButton {
                        width: 90
                        visible: maker.duplicate !== null
                        appearance: root.appearance
                        label: "Open"
                        onActivated: maker.openApp(maker.duplicate)
                    }

                    Panels.PopupButton {
                        width: 90
                        appearance: root.appearance
                        label: "Pick icon"
                        labelColor: theme.textMuted
                        onActivated: root.webApps.pickIcon()
                    }

                    Panels.PopupButton {
                        width: 90
                        appearance: root.appearance
                        interactive: maker.canCreate
                        color: maker.canCreate ? theme.accent : theme.backgroundSecondary
                        label: root.webApps.creating ? "Creating…" : "Create"
                        labelColor: maker.canCreate ? theme.background : theme.textDisabled
                        onActivated: maker.create()
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    visible: root.webApps.apps.length > 0
                    color: theme.border
                }

                Panels.ShellText {
                    visible: root.webApps.apps.length > 0
                    text: "Web apps"
                    color: theme.textMuted
                    font.pixelSize: root.appearance.textSize - 1
                    font.bold: true
                }

                ListView {
                    id: list

                    width: parent.width
                    height: Math.min(contentHeight, 5 * 44)
                    visible: root.webApps.apps.length > 0
                    clip: true
                    spacing: 2
                    model: root.webApps.apps
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Panels.PopupRow {
                        id: row

                        required property var modelData
                        readonly property bool armed: maker.deleteArmed === modelData.id

                        width: ListView.view.width
                        height: 42
                        appearance: root.appearance

                        Image {
                            id: rowIcon

                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 26
                            height: 26
                            sourceSize.width: 52
                            sourceSize.height: 52
                            fillMode: Image.PreserveAspectFit
                            source: IconSource.forName(row.modelData.icon)
                        }

                        Column {
                            anchors.left: rowIcon.right
                            anchors.leftMargin: 10
                            anchors.right: actions.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter

                            Panels.ShellText {
                                width: parent.width
                                text: row.armed ? "Delete " + row.modelData.name + "?" : row.modelData.name
                                elide: Text.ElideRight
                                color: row.armed ? theme.red : theme.text
                                font.pixelSize: root.appearance.textSize - 1
                            }

                            Panels.ShellText {
                                width: parent.width
                                text: row.modelData.url
                                elide: Text.ElideMiddle
                                color: theme.textMuted
                                font.pixelSize: root.appearance.textSize - 3
                            }
                        }

                        TapHandler {
                            enabled: !row.armed
                            onTapped: maker.openApp(row.modelData)
                        }

                        Row {
                            id: actions

                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Panels.PopupButton {
                                width: 64
                                visible: row.armed
                                appearance: root.appearance
                                label: "Delete"
                                labelColor: theme.red
                                onActivated: {
                                    maker.deleteArmed = "";
                                    root.webApps.remove(row.modelData.id);
                                }
                            }

                            Panels.PopupButton {
                                width: 64
                                visible: row.armed
                                appearance: root.appearance
                                label: "Cancel"
                                onActivated: maker.deleteArmed = ""
                            }

                            Panels.PopupButton {
                                width: 30
                                visible: !row.armed
                                appearance: root.appearance
                                label: "󰆴"
                                labelColor: theme.textMuted
                                labelSize: root.appearance.textSize + 2
                                onActivated: maker.deleteArmed = row.modelData.id
                            }
                        }
                    }
                }
            }
        }
    }
}
