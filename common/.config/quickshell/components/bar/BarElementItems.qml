import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Widgets
import QtQuick
import "../../config" as Config
import "../../config/BarProfileModel.js" as BarProfileModel
import "../StatusText.js" as StatusText
import "BarElementItems.js" as BarElementItems
import "BarLayout.js" as BarLayout
import "LiveElements.js" as LiveElements
import "../panels/ControlCenterNames.js" as Names
import "../panels/MediaCard.js" as MediaCard
import "RecordingIndicator.js" as RecordingIndicator
import "PrivacyIndicator.js" as PrivacyIndicator
import "PomodoroRing.js" as PomodoroRing
import ".." as Components

// The bar elements that need no component of their own (notifications,
// recording, privacy, keep-awake, media, cava, audio, bluetooth, tray, network, battery, clock
// and pomodoro),
// placed by the bar's single walk per zone (see BarContent).
Item {
    id: root

    required property var appearance
    required property var monitorScreen
    required property var pomodoro
    required property var notificationHistory
    required property var screenCapture
    // The shell's keep-awake (services/KeepAwake.qml).
    required property var keepAwake
    // The screens other apps share, with their start times
    // (services/ScreenShares.qml).
    required property var screenShares
    // The apps using the microphone or a camera (services/DeviceCaptures.qml).
    required property var deviceCaptures
    // The shared cava process (services/Cava.qml).
    required property var cava
    // Whether the bar holding these elements is shown on its monitor.
    property bool barVisible: true
    property string activePopup: ""
    // How an element, by id, looks in the capsule's row mid-crossfade or
    // entering, { opacity, scale, slide } (CapsuleMotion.rowLook): every
    // element in it takes it, live ones beside the pills don't. Always
    // { 1, 1, 0 } on any other bar style.
    property var rowLook: element => ({ opacity: 1, scale: 1, slide: 0 })
    // Where each element goes, provided by the bar's single walk per zone.
    property var elementX: element => 0
    property var elementY: element => 0
    // Whether an element sits in a group, provided by the bar's walk.
    property var elementGrouped: element => false
    signal popupRequested(string popup)

    readonly property var audio: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
        ? Pipewire.defaultAudioSink.audio : null
    readonly property real volumeLevel: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
        ? Pipewire.defaultAudioSink.audio.volume : 0
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery && battery.isPresent
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    // How long free text gets: the media title, and the apps sharing the screen
    // on a side bar.
    readonly property real longTextMaximumLength: monitorScreen
        ? Math.max(96, Math.min(260, BarLayout.screenLength(appearance, monitorScreen) * 0.12)) : 260
    property var player: null
    readonly property string playerLabel: player
        ? (player.trackTitle !== "" ? player.trackTitle : player.identity) : ""
    property string displayedPlayerLabel: playerLabel
    // What is recording, for the recording indicator.
    readonly property var recordings: RecordingIndicator.recordings(screenCapture.recordingStartedAt, screenShares.shares)
    property real recordingNow: Date.now()
    // Which apps share the screen, shown for a moment after a click that
    // can't stop anything.
    property string sharingShown: ""
    readonly property real itemHeight: BarLayout.elementThickness(appearance)

    // Whether the bar is a capsule at rest, where the elements show their
    // at-rest icon and text.
    readonly property bool resting: BarProfileModel.resting(appearance)

    // Whether element `id` shows its icon and its text, { icon, text }.
    function shown(id) {
        return BarProfileModel.iconTextShown(appearance.barElements, id, resting);
    }

    Config.Theme {
        id: theme
    }

    // The size of an element this long along the bar, `thickness` across it
    // (itemHeight unless given). On a side bar it runs down, and is as thick
    // across the bar as on any other.
    function elementSize(length, thickness) {
        return BarLayout.size(appearance, length, thickness === undefined ? itemHeight : thickness);
    }

    // How long `content` is along the bar.
    function contentLength(content) {
        return BarLayout.itemLength(appearance, {
            width: content.implicitWidth,
            height: content.implicitHeight
        });
    }

    // The size of an element around its content, with the padding along the bar.
    function sizeAround(content, thickness) {
        return elementSize(contentLength(content) + BarElementItems.elementPadding * 2, thickness);
    }

    // The size of a square element (network, Bluetooth, tray) around its
    // glyph, `content` (see BarElementItems.elementLength).
    function squareSize(element, content) {
        return elementSize(BarElementItems.elementLength(element, contentLength(content), appearance,
            id => itemVisible(id)));
    }

    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    function activePlayer() {
        const players = Mpris.players.values;

        for (let index = 0; index < players.length; index++) {
            if (players[index].isPlaying)
                return players[index];
        }

        return players.length > 0 ? players[0] : null;
    }

    function updatePlayer() {
        player = activePlayer();
    }

    // The item of each bar element drawn here, by element id.
    readonly property var items: ({
        "notifications": notificationButton,
        "recording": recordingItem,
        "privacy": privacyItem,
        "keepAwake": keepAwakeItem,
        "media": mediaItem,
        "cava": cavaElement,
        "audio": audioButton,
        "bluetooth": bluetoothButton,
        "tray": trayButton,
        "network": networkButton,
        "battery": batteryItem,
        "clock": clockButton,
        "pomodoro": pomodoroItem
    })

    // On a capsule, its live elements, beside its workspace pills
    // (LiveElements.liveElements): they fade in and out and slide with
    // the pills. None on any other bar style.
    readonly property var liveIds: LiveElements.ids(appearance.liveElements)

    // Whether `element` is one of this capsule's live elements, drawn beside
    // its workspace pills; never on any other bar style.
    function live(element) {
        return liveIds.indexOf(element) !== -1;
    }

    // The sizes an element is drawn at: a live element's are smaller
    // (LiveElements.elementSizes).
    function sizes(element) {
        return LiveElements.elementSizes(appearance, live(element));
    }

    // What there is for the elements to show (see BarElementItems.itemVisible).
    readonly property var elementStatus: ({
        live: liveIds,
        expanded: appearance.capsuleExpanded === true,
        player: player,
        recordings: recordings,
        keepAwakeOn: keepAwake.on,
        hasBattery: hasBattery,
        onBattery: UPower.onBattery,
        cavaSilent: cava.silent,
        pomodoroStarted: pomodoro.started,
        captures: deviceCaptures.captures,
        glance: appearance.glanceElements || []
    })

    // Enabled elements with nothing to show (no player, battery, recording,
    // sound or pomodoro started) are hidden, and so are live elements of a collapsed capsule
    // while they aren't active; see BarElementItems.js.
    function itemVisible(element) {
        return BarElementItems.itemVisible(element, appearance.barElements, elementStatus);
    }

    // Whether a live element is active (LiveElements.active): whether a
    // collapsed capsule shows it.
    function liveActive(element) {
        return live(element) && LiveElements.active(element, elementStatus);
    }

    Component.onCompleted: updatePlayer()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updatePlayer()
    }

    onPlayerLabelChanged: mediaLabelTransition.restart()

    // The network devices as plain values, { connected, wifi, signalStrength,
    // name }: a Wi-Fi device's are its connected network's.
    function networkDevices() {
        return Networking.devices.values.map(device => {
            const wifi = DeviceType.toString(device.type) === "Wifi";
            const network = wifi && device.networks
                ? device.networks.values.find(candidate => candidate.connected) : null;
            return {
                connected: device.connected,
                wifi: wifi,
                signalStrength: network ? network.signalStrength : 0,
                name: network ? network.name : ""
            };
        });
    }

    // A Wi-Fi device shows its connected network's signal.
    function networkIcon() {
        return StatusText.networkIcon(networkDevices());
    }

    // What the capsule glance's cards show (CapsuleGlance.cards), as plain
    // values: the player media follows, the battery, null without either,
    // and the network devices.
    readonly property var glanceStatus: ({
        player: player ? {
            trackTitle: player.trackTitle,
            trackArtist: player.trackArtist,
            trackArtUrl: player.trackArtUrl,
            identity: player.identity,
            isPlaying: player.isPlaying
        } : null,
        battery: hasBattery ? {
            isPresent: true,
            percentage: battery.percentage,
            state: battery.state,
            timeToEmpty: battery.timeToEmpty
        } : null,
        networks: networkDevices()
    })
    // UPower's device states, for CapsuleGlance.cards.
    readonly property var batteryStates: UPowerDeviceState

    Rectangle {
        id: notificationButton

        readonly property var size: root.sizeAround(notificationContent)

        visible: root.itemVisible("notifications")
        RowLook { target: notificationButton; look: root.rowLook("notifications") }
        x: root.elementX("notifications")
        y: root.elementY("notifications")
        width: size.width
        height: size.height
        radius: root.appearance.radius
        color: notificationHover.hovered ? theme.surfaceHover
            : root.elementGrouped("notifications") || !BarProfileModel.elementPillsDrawn(root.appearance)
                ? "transparent" : theme.surface
        border.width: BarProfileModel.elementBorderDrawn(root.appearance) && !root.elementGrouped("notifications") ? 1 : 0
        border.color: root.appearance.elementBorder ? theme.border : "transparent"

        Behavior on color {
            ColorAnimation { duration: root.appearance.motion.short }
        }

        HoverHandler {
            id: notificationHover
        }

        IconValue {
            id: notificationContent

            anchors.centerIn: parent
            appearance: root.appearance
            gap: 5
            icon: root.appearance.doNotDisturb ? "󰂛" : "󰂚"
            iconColor: root.appearance.doNotDisturb ? theme.yellow
                : root.notificationHistory.unreadCount > 0 ? theme.accent : theme.textMuted
            iconSize: root.appearance.iconSize
            value: root.notificationHistory.unreadCount > 99 ? "99+"
                : root.notificationHistory.unreadCount
            valueVisible: BarProfileModel.elementOption(root.appearance.barElements, "notifications", "badgeVisible")
                && root.notificationHistory.unreadCount > 0
            valueColor: root.appearance.doNotDisturb ? theme.yellow : theme.accent
            valueSize: root.appearance.textSize - 2
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.popupRequested(Names.controlCenter.popup)
        }
    }

    LiveCapableItem {
        id: recordingItem

        appearance: root.appearance
        element: "recording"
        items: root

        Rectangle {
            id: recordingButton

            readonly property var size: root.sizeAround(recordingContent, recordingItem.sizes.thickness)
            width: size.width
            height: size.height
            radius: root.appearance.radius
            color: recordingHover.hovered ? theme.surfaceHover
                : root.elementGrouped("recording") || !BarProfileModel.elementPillsDrawn(root.appearance)
                    ? "transparent" : theme.surface
            border.width: BarProfileModel.elementBorderDrawn(root.appearance) && !root.elementGrouped("recording") ? 1 : 0
            border.color: root.appearance.elementBorder ? theme.border : "transparent"

            Behavior on color {
                ColorAnimation { duration: root.appearance.motion.short }
            }

            HoverHandler {
                id: recordingHover
            }

            RecordingContent {
                id: recordingContent

                anchors.centerIn: parent
                appearance: root.appearance
                iconColor: theme.red
                iconSize: recordingItem.sizes.iconSize
                textSize: recordingItem.sizes.textSize
                iconVisible: root.shown("recording").icon
                textVisible: root.shown("recording").text
                elapsed: RecordingIndicator.elapsedSince(root.recordings, root.recordingNow)
                sharing: root.sharingShown
                maximumLength: root.longTextMaximumLength
            }

            // Ticks the elapsed time only while the indicator is shown.
            Timer {
                interval: 1000
                repeat: true
                triggeredOnStart: true
                running: recordingButton.visible
                onTriggered: root.recordingNow = Date.now()
            }

            Timer {
                id: sharingShownTimer

                interval: 4000
                onTriggered: root.sharingShown = ""
            }

            TapHandler {
                onTapped: {
                    if (RecordingIndicator.stoppable(root.recordings)) {
                        root.screenCapture.stopRecording();
                    } else {
                        root.sharingShown = RecordingIndicator.sharingText(root.recordings);
                        sharingShownTimer.restart();
                    }
                }
            }
        }
    }

    // The privacy indicator: the mic icon, the camera icon or both while an
    // app uses them, hidden otherwise. It opens the popup listing the apps.
    LiveCapableItem {
        id: privacyItem

        appearance: root.appearance
        element: "privacy"
        items: root

        Rectangle {
            id: privacyButton

            readonly property var icons: PrivacyIndicator.icons(root.deviceCaptures.captures)
            readonly property var size: root.sizeAround(privacyContent, privacyItem.sizes.thickness)

            width: size.width
            height: size.height
            radius: root.appearance.radius
            color: privacyHover.hovered ? theme.surfaceHover
                : root.elementGrouped("privacy") || !BarProfileModel.elementPillsDrawn(root.appearance) ? "transparent" : theme.surface
            border.width: BarProfileModel.elementBorderDrawn(root.appearance) && !root.elementGrouped("privacy") ? 1 : 0
            border.color: root.appearance.elementBorder ? theme.border : "transparent"

            Behavior on color {
                ColorAnimation { duration: root.appearance.motion.short }
            }

            HoverHandler {
                id: privacyHover
            }

            // The mic and the camera, one after the other along the bar.
            IconValue {
                id: privacyContent

                anchors.centerIn: parent
                appearance: root.appearance
                icon: privacyButton.icons[0] || ""
                iconColor: theme.orange
                iconSize: privacyItem.sizes.iconSize
                value: privacyButton.icons[1] || ""
                valueVisible: privacyButton.icons.length > 1
                valueSize: privacyItem.sizes.iconSize
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.popupRequested("privacy")
            }
        }
    }

    LiveCapableItem {
        id: keepAwakeItem

        appearance: root.appearance
        element: "keepAwake"
        items: root

        KeepAwakeElement {
            id: keepAwakeButton

            appearance: root.appearance
            keepAwake: root.keepAwake
            grouped: root.elementGrouped("keepAwake")
            sizes: keepAwakeItem.sizes
            live: keepAwakeItem.live
            onPopupRequested: root.popupRequested("keepAwake")
        }
    }

    LiveCapableItem {
        id: mediaItem

        appearance: root.appearance
        element: "media"
        items: root

        Rectangle {
            id: mediaButton

            readonly property var size: root.elementSize(mediaContent.implicitWidth + 16, mediaItem.sizes.thickness)

            border.width: BarProfileModel.elementBorderDrawn(root.appearance) && !root.elementGrouped("media") ? 1 : 0
            border.color: root.appearance.elementBorder ? theme.border : "transparent"
            width: size.width
            height: size.height
            radius: root.appearance.radius
            color: mediaHover.hovered ? theme.surfaceHover
                : root.elementGrouped("media") || !BarProfileModel.elementPillsDrawn(root.appearance) ? "transparent" : theme.surface

            Behavior on color {
                ColorAnimation { duration: root.appearance.motion.short }
            }

            HoverHandler {
                id: mediaHover
            }

            AlongBarBehavior on width { appearance: root.appearance }
            AlongBarBehavior on height { appearance: root.appearance }

            Row {
                id: mediaContent

                anchors.centerIn: parent
                spacing: 7
                // The title runs sideways on a side bar, the note stays upright.
                rotation: BarLayout.turn(root.appearance)

                // Live, beside a capsule's pills, the art stands in for the
                // note, as a small rounded thumbnail, once it loads.
                ClippingRectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: mediaItem.live && mediaThumbnail.status === Image.Ready
                    width: mediaItem.sizes.iconSize + 4
                    height: width
                    radius: Math.max(3, width / 4)
                    color: "transparent"

                    Image {
                        id: mediaThumbnail

                        anchors.fill: parent
                        source: mediaItem.live && root.player ? root.player.trackArtUrl : ""
                        sourceSize.width: 48
                        sourceSize.height: 48
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                ShellText {
                    anchors.verticalCenter: parent.verticalCenter
                    rotation: -parent.rotation
                    visible: root.shown("media").icon
                        && !(mediaItem.live && mediaThumbnail.status === Image.Ready)
                    text: "󰎈"
                    color: theme.green
                    font.pixelSize: mediaItem.sizes.iconSize
                    font.bold: true
                }

                ShellText {
                    id: mediaTitle

                    property string displayedLabel: root.displayedPlayerLabel

                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.shown("media").text
                    width: Math.min(root.longTextMaximumLength, implicitWidth)
                    text: displayedLabel
                    color: theme.green
                    elide: Text.ElideRight
                    font.pixelSize: mediaItem.sizes.textSize
                    font.bold: true

                    transform: Translate {
                        id: mediaLabelTranslation
                    }
                }

                // Live, moving bars follow: cava's, or an equaliser when cava
                // can't run (MediaCard.liveBars).
                MediaLiveBars {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: mediaItem.live
                    height: Math.round(mediaItem.sizes.iconSize * 0.8)
                    width: implicitWidth
                    barCount: 4
                    barWidth: 2
                    cava: root.cava
                    motion: root.appearance.motion
                    playing: !!root.player && root.player.isPlaying
                    drawing: mediaItem.live && root.liveActive("media") && root.barVisible
                    smoothing: bars.source === "cava" ? root.appearance.motion.frame
                        : Math.min(root.appearance.motion.frame * 3, equaliserInterval)
                }

                SequentialAnimation {
                    id: mediaLabelTransition

                    NumberAnimation {
                        target: mediaLabelTranslation
                        property: "x"
                        to: -12
                        duration: root.appearance.motion.brief
                    }

                    ScriptAction {
                        script: {
                            root.displayedPlayerLabel = root.playerLabel;
                            mediaLabelTranslation.x = 12;
                        }
                    }

                    NumberAnimation {
                        target: mediaLabelTranslation
                        property: "x"
                        to: 0
                        duration: root.appearance.motion.medium
                        easing.type: root.appearance.motion.easing
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.popupRequested("media")

                // Scrolling skips the player shown to the next or previous
                // track, at most one per notch or touchpad gesture.
                Components.WheelStepHandler {
                    onStepped: step => MediaCard.skipTrack(root.player, step)
                }
            }
        }
    }

    // Cava hides in silence and opens nothing.
    Rectangle {
        id: cavaElement

        readonly property var size: root.sizeAround(cavaBars)

        // While drawn, it keeps the shared cava process running, computing
        // at least its bar count. Hidden in silence still counts as drawn, so
        // cava hears the sound that shows it again.
        readonly property bool drawing: BarProfileModel.elementEnabled(root.appearance.barElements, "cava")
            && root.barVisible
        readonly property var options: BarProfileModel.elementOptions(root.appearance.barElements, "cava")
        readonly property int barCount: options.barCount

        visible: root.itemVisible("cava")
        RowLook { target: cavaElement; look: root.rowLook("cava") }
        x: root.elementX("cava")
        y: root.elementY("cava")
        width: size.width
        height: size.height
        radius: root.appearance.radius
        color: root.elementGrouped("cava") || !BarProfileModel.elementPillsDrawn(root.appearance) ? "transparent" : theme.surface
        border.width: BarProfileModel.elementBorderDrawn(root.appearance) && !root.elementGrouped("cava") ? 1 : 0
        border.color: root.appearance.elementBorder ? theme.border : "transparent"

        onDrawingChanged: root.cava.setDrawing(cavaElement, drawing)
        Component.onCompleted: root.cava.setDrawing(cavaElement, drawing)
        Component.onDestruction: root.cava.setDrawing(cavaElement, false)

        // The bars stand on the baseline of the other elements' text, which
        // is centered in the element like this text would be.
        FontMetrics {
            id: cavaTextMetrics

            font.family: theme.fontFamily
            font.pixelSize: root.appearance.textSize
            font.bold: true
        }

        CavaBars {
            id: cavaBars

            readonly property real textBaseline: (parent.height - cavaTextMetrics.height) / 2
                + cavaTextMetrics.ascent

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: sideBar ? parent.verticalCenter : undefined
            y: 2
            width: sideBar ? parent.width - 6 : implicitWidth
            height: sideBar ? implicitHeight : Math.max(1, textBaseline - y)
            barPosition: root.appearance.barPosition
            frame: root.cava.heights
            barCount: cavaElement.barCount
            barWidth: cavaElement.options.barWidth
            colorName: cavaElement.options.color
            smoothing: root.appearance.motion.frame
        }
    }

    Rectangle {
        id: audioButton

        readonly property var size: root.sizeAround(audioContent)

        visible: root.itemVisible("audio")
        RowLook { target: audioButton; look: root.rowLook("audio") }
        x: root.elementX("audio")
        y: root.elementY("audio")
        width: size.width
        height: size.height
        radius: root.appearance.radius
        color: audioHover.hovered ? theme.surfaceHover
            : root.elementGrouped("audio") || !BarProfileModel.elementPillsDrawn(root.appearance) ? "transparent" : theme.surface

        border.width: BarProfileModel.elementBorderDrawn(root.appearance) && !root.elementGrouped("audio") ? 1 : 0
        border.color: root.appearance.elementBorder ? theme.border : "transparent"

        Behavior on color {
            ColorAnimation { duration: root.appearance.motion.short }
        }

        HoverHandler {
            id: audioHover
        }

        AudioLevel {
            id: audioContent

            anchors.centerIn: parent
            appearance: root.appearance
            volume: root.volumeLevel
            muted: !root.audio || root.audio.muted
            meterVisible: BarProfileModel.elementOption(root.appearance.barElements, "audio", "meterVisible")
            iconVisible: root.shown("audio").icon
            textVisible: root.shown("audio").text
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.popupRequested("audio")
        }
    }

    Rectangle {
        id: bluetoothButton

        // Square while it draws its own pill, padded like the others when
        // not (BarElementItems.elementLength).
        readonly property var size: root.squareSize("bluetooth", bluetoothGlyph)

        visible: root.itemVisible("bluetooth")
        RowLook { target: bluetoothButton; look: root.rowLook("bluetooth") }
        x: root.elementX("bluetooth")
        y: root.elementY("bluetooth")
        width: size.width
        height: size.height
        radius: root.appearance.radius
        color: bluetoothHover.hovered ? theme.surfaceHover
            : root.elementGrouped("bluetooth") || !BarProfileModel.elementPillsDrawn(root.appearance) ? "transparent" : theme.surface

        border.width: BarProfileModel.elementBorderDrawn(root.appearance) && !root.elementGrouped("bluetooth") ? 1 : 0
        border.color: root.appearance.elementBorder ? theme.border : "transparent"

        Behavior on color {
            ColorAnimation { duration: root.appearance.motion.short }
        }

        HoverHandler {
            id: bluetoothHover
        }

        ShellText {
            id: bluetoothGlyph

            anchors.centerIn: parent
            text: root.bluetoothAdapter && root.bluetoothAdapter.enabled ? "󰂯" : "󰂲"
            color: theme.blue
            font.pixelSize: root.appearance.iconSize
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.popupRequested("bluetooth")
        }
    }

    Rectangle {
        id: trayButton

        // Square while it draws its own pill, padded like the others when
        // not (BarElementItems.elementLength).
        readonly property var size: root.squareSize("tray", trayGlyph)

        visible: root.itemVisible("tray")
        RowLook { target: trayButton; look: root.rowLook("tray") }
        x: root.elementX("tray")
        y: root.elementY("tray")
        width: size.width
        height: size.height
        radius: root.appearance.radius
        color: trayHover.hovered ? theme.surfaceHover
            : root.elementGrouped("tray") || !BarProfileModel.elementPillsDrawn(root.appearance) ? "transparent" : theme.surface

        border.width: BarProfileModel.elementBorderDrawn(root.appearance) && !root.elementGrouped("tray") ? 1 : 0
        border.color: root.appearance.elementBorder ? theme.border : "transparent"

        Behavior on color {
            ColorAnimation { duration: root.appearance.motion.short }
        }

        HoverHandler {
            id: trayHover
        }

        ShellText {
            id: trayGlyph

            anchors.centerIn: parent
            text: StatusText.trayIcon(root.appearance.barPosition, root.activePopup === "tray")
            color: theme.green
            font.pixelSize: root.appearance.iconSize
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.popupRequested("tray")
        }
    }

    Rectangle {
        id: networkButton

        // Square while it draws its own pill, padded like the others when
        // not (BarElementItems.elementLength).
        readonly property var size: root.squareSize("network", networkGlyph)

        visible: root.itemVisible("network")
        RowLook { target: networkButton; look: root.rowLook("network") }
        x: root.elementX("network")
        y: root.elementY("network")
        width: size.width
        height: size.height
        radius: root.appearance.radius
        color: networkHover.hovered ? theme.surfaceHover
            : root.elementGrouped("network") || !BarProfileModel.elementPillsDrawn(root.appearance) ? "transparent" : theme.surface

        border.width: BarProfileModel.elementBorderDrawn(root.appearance) && !root.elementGrouped("network") ? 1 : 0
        border.color: root.appearance.elementBorder ? theme.border : "transparent"

        Behavior on color {
            ColorAnimation { duration: root.appearance.motion.short }
        }

        HoverHandler {
            id: networkHover
        }

        ShellText {
            id: networkGlyph

            anchors.centerIn: parent
            text: root.networkIcon()
            color: theme.purple
            // A little bigger, like the battery, so the signal reads at a glance.
            font.pixelSize: root.appearance.iconSize + 4
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.popupRequested("network")
        }
    }

    LiveCapableItem {
        id: batteryItem

        appearance: root.appearance
        element: "battery"
        items: root

        Rectangle {
            id: batteryButton

            readonly property var size: root.sizeAround(batteryContent, batteryItem.sizes.thickness)

            width: size.width
            height: size.height
            radius: root.appearance.radius
            color: batteryHover.hovered ? theme.surfaceHover
                : root.elementGrouped("battery") || !BarProfileModel.elementPillsDrawn(root.appearance) ? "transparent" : theme.surface

            border.width: BarProfileModel.elementBorderDrawn(root.appearance) && !root.elementGrouped("battery") ? 1 : 0
            border.color: root.appearance.elementBorder ? theme.border : "transparent"

            Behavior on color {
                ColorAnimation { duration: root.appearance.motion.short }
            }

            HoverHandler {
                id: batteryHover
            }

            IconValue {
                id: batteryContent

                anchors.centerIn: parent
                appearance: root.appearance
                icon: StatusText.batteryIcon(root.battery, UPowerDeviceState)
                iconColor: theme.yellow
                // The battery glyphs are narrow: a little bigger, they read at a glance.
                iconSize: batteryItem.sizes.iconSize + 4
                valueSize: batteryItem.sizes.textSize
                value: Math.round(root.battery.percentage * 100) + "%"
                iconVisible: root.shown("battery").icon
                valueVisible: root.shown("battery").text
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.popupRequested("battery")
            }
        }
    }

    // The clock opens the pomodoro's popup, where a pomodoro is started.
    Rectangle {
        id: clockButton

        readonly property var size: root.sizeAround(clockContent)

        visible: root.itemVisible("clock")
        RowLook { target: clockButton; look: root.rowLook("clock") }
        x: root.elementX("clock")
        y: root.elementY("clock")
        width: size.width
        height: size.height
        radius: root.appearance.radius
        color: clockHover.hovered ? theme.surfaceHover
            : root.elementGrouped("clock") || !BarProfileModel.elementPillsDrawn(root.appearance) ? "transparent" : theme.surface

        border.width: BarProfileModel.elementBorderDrawn(root.appearance) && !root.elementGrouped("clock") ? 1 : 0
        border.color: root.appearance.elementBorder ? theme.border : "transparent"

        Behavior on color {
            ColorAnimation { duration: root.appearance.motion.short }
        }

        HoverHandler {
            id: clockHover
        }

        Clock {
            id: clockContent

            anchors.centerIn: parent
            appearance: root.appearance
            color: theme.orange
            iconVisible: root.shown("clock").icon
            valueVisible: root.shown("clock").text
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.popupRequested("pomodoro")
        }
    }

    // The pomodoro's countdown, shown only while one is started: green while
    // it runs, muted while paused. It opens the same popup as the clock. As
    // a capsule's live element it shows while started, paused included, as
    // a tiny ring of the time left in the phase, in the phase's colour
    // (PomodoroRing.js), and mm:ss.
    LiveCapableItem {
        id: pomodoroItem

        appearance: root.appearance
        element: "pomodoro"
        items: root

        Rectangle {
            id: pomodoroButton

            readonly property Item content: pomodoroItem.live ? pomodoroLiveContent : pomodoroContent
            readonly property var size: root.sizeAround(content, pomodoroItem.sizes.thickness)
            readonly property color phaseColor: PomodoroRing.phaseColor(root.pomodoro.phase, theme)

            width: size.width
            height: size.height
            radius: root.appearance.radius
            color: pomodoroHover.hovered ? theme.surfaceHover
                : root.elementGrouped("pomodoro") || !BarProfileModel.elementPillsDrawn(root.appearance) ? "transparent" : theme.surface

            border.width: BarProfileModel.elementBorderDrawn(root.appearance) && !root.elementGrouped("pomodoro") ? 1 : 0
            border.color: root.appearance.elementBorder ? theme.border : "transparent"

            Behavior on color {
                ColorAnimation { duration: root.appearance.motion.short }
            }

            HoverHandler {
                id: pomodoroHover
            }

            IconValue {
                id: pomodoroContent

                visible: !pomodoroItem.live
                anchors.centerIn: parent
                appearance: root.appearance
                icon: "󰔟"
                iconColor: root.pomodoro.running ? theme.green : theme.textMuted
                iconSize: pomodoroItem.sizes.iconSize
                valueSize: pomodoroItem.sizes.textSize
                value: root.pomodoro.remainingLabel
            }

            Row {
                id: pomodoroLiveContent

                visible: pomodoroItem.live
                anchors.centerIn: parent
                spacing: 5

                PomodoroRingShape {
                    anchors.verticalCenter: parent.verticalCenter
                    size: pomodoroItem.sizes.iconSize
                    thickness: 2
                    fraction: PomodoroRing.fraction(root.pomodoro.remainingSeconds, root.pomodoro.phaseSeconds)
                    color: pomodoroButton.phaseColor
                    trackColor: theme.surfaceHover
                    opacity: root.pomodoro.running ? 1 : 0.6
                }

                ElementText {
                    anchors.verticalCenter: parent.verticalCenter
                    appearance: root.appearance
                    value: root.pomodoro.remainingLabel
                    color: root.pomodoro.running ? theme.text : theme.textMuted
                    font.pixelSize: pomodoroItem.sizes.textSize
                    font.bold: true
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.popupRequested("pomodoro")
            }
        }
    }
}
