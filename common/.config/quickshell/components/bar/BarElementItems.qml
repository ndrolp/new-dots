import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import QtQuick
import "../../config" as Config
import "../../config/BarProfileModel.js" as BarProfileModel
import "../StatusText.js" as StatusText
import "BarElementItems.js" as BarElementItems
import "BarLayout.js" as BarLayout
import "../panels/ControlCenterNames.js" as Names
import "RecordingIndicator.js" as RecordingIndicator

// The bar elements that need no component of their own (notifications,
// recording, keep-awake, media, cava, audio, bluetooth, tray, network, battery and clock),
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
    // The shared cava process (services/Cava.qml).
    required property var cava
    // Whether the bar holding these elements is shown on its monitor.
    property bool barVisible: true
    property string activePopup: ""
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

    Config.Theme {
        id: theme
    }

    // The size of an element this long along the bar. On a side bar it runs
    // down, and is as thick across the bar as on any other.
    function elementSize(length) {
        return BarLayout.size(appearance, length, itemHeight);
    }

    // The size of an element around its content, with the padding along the bar.
    function sizeAround(content) {
        return elementSize(BarLayout.itemLength(appearance, {
            width: content.implicitWidth,
            height: content.implicitHeight
        }) + 16);
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
        "recording": recordingButton,
        "keepAwake": keepAwakeButton,
        "media": mediaButton,
        "cava": cavaElement,
        "audio": audioButton,
        "bluetooth": bluetoothButton,
        "tray": trayButton,
        "network": networkButton,
        "battery": batteryButton,
        "clock": pomodoroButton
    })

    // Enabled elements with nothing to show (no player, battery, recording
    // or sound) are hidden; see BarElementItems.js.
    function itemVisible(element) {
        return BarElementItems.itemVisible(element, appearance.barElements, {
            hasPlayer: player !== null,
            hasBattery: hasBattery,
            recording: RecordingIndicator.shown(recordings),
            cavaSilent: cava.silent
        });
    }

    Component.onCompleted: updatePlayer()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updatePlayer()
    }

    onPlayerLabelChanged: mediaLabelTransition.restart()

    function networkIcon() {
        return StatusText.networkIcon(Networking.devices.values.map(device => ({
            connected: device.connected,
            wifi: DeviceType.toString(device.type) === "Wifi"
        })));
    }

    Rectangle {
        id: notificationButton

        readonly property var size: root.sizeAround(notificationContent)

        visible: root.itemVisible("notifications")
        x: root.elementX("notifications")
        y: root.elementY("notifications")
        width: size.width
        height: size.height
        radius: root.appearance.radius
        color: notificationHover.hovered ? theme.surfaceHover
            : root.elementGrouped("notifications") || root.appearance.pillsTransparent
                || root.appearance.transparentBarSlanted
                ? "transparent" : theme.surface
        border.width: root.appearance.elementBorder && !root.elementGrouped("notifications") ? 1 : 0
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

    Rectangle {
        id: recordingButton

        readonly property var size: root.sizeAround(recordingContent)

        visible: root.itemVisible("recording")
        x: root.elementX("recording")
        y: root.elementY("recording")
        width: size.width
        height: size.height
        radius: root.appearance.radius
        color: recordingHover.hovered ? theme.surfaceHover
            : root.elementGrouped("recording") || root.appearance.pillsTransparent
                || root.appearance.transparentBarSlanted
                ? "transparent" : theme.surface
        border.width: root.appearance.elementBorder && !root.elementGrouped("recording") ? 1 : 0
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

    KeepAwakeElement {
        id: keepAwakeButton

        appearance: root.appearance
        keepAwake: root.keepAwake
        grouped: root.elementGrouped("keepAwake")
        visible: root.itemVisible("keepAwake")
        x: root.elementX("keepAwake")
        y: root.elementY("keepAwake")
        onPopupRequested: root.popupRequested("keepAwake")
    }

    Rectangle {
        id: mediaButton

        readonly property var size: root.elementSize(mediaContent.implicitWidth + 16)

        border.width: root.appearance.elementBorder && !root.elementGrouped("media") ? 1 : 0
        border.color: root.appearance.elementBorder ? theme.border : "transparent"
        visible: root.itemVisible("media")
        x: root.elementX("media")
        y: root.elementY("media")
        width: size.width
        height: size.height
        radius: root.appearance.radius
        color: mediaHover.hovered ? theme.surfaceHover
            : root.elementGrouped("media") || root.appearance.pillsTransparent
                || root.appearance.transparentBarSlanted ? "transparent" : theme.surface


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

            Text {
                anchors.verticalCenter: parent.verticalCenter
                rotation: -parent.rotation
                text: "󰎈"
                color: theme.green
                font.pixelSize: root.appearance.iconSize
                font.bold: true
            }

            Text {
                id: mediaTitle

                property string displayedLabel: root.displayedPlayerLabel

                anchors.verticalCenter: parent.verticalCenter
                visible: BarProfileModel.elementOption(root.appearance.barElements, "media", "titleVisible")
                width: Math.min(root.longTextMaximumLength, implicitWidth)
                text: displayedLabel
                color: theme.green
                elide: Text.ElideRight
                font.pixelSize: root.appearance.textSize
                font.bold: true

                transform: Translate {
                    id: mediaLabelTranslation
                }
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
        x: root.elementX("cava")
        y: root.elementY("cava")
        width: size.width
        height: size.height
        radius: root.appearance.radius
        color: root.elementGrouped("cava") || root.appearance.pillsTransparent
            || root.appearance.transparentBarSlanted ? "transparent" : theme.surface
        border.width: root.appearance.elementBorder && !root.elementGrouped("cava") ? 1 : 0
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
        x: root.elementX("audio")
        y: root.elementY("audio")
        width: size.width
        height: size.height
        radius: root.appearance.radius
        color: audioHover.hovered ? theme.surfaceHover
            : root.elementGrouped("audio") || root.appearance.pillsTransparent
                || root.appearance.transparentBarSlanted ? "transparent" : theme.surface

        border.width: root.appearance.elementBorder && !root.elementGrouped("audio") ? 1 : 0
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
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.popupRequested("audio")
        }
    }

    Rectangle {
        id: bluetoothButton

        readonly property var size: root.elementSize(root.appearance.workspaceButtonSize)

        visible: root.itemVisible("bluetooth")
        x: root.elementX("bluetooth")
        y: root.elementY("bluetooth")
        width: size.width
        height: size.height
        radius: root.appearance.radius
        color: bluetoothHover.hovered ? theme.surfaceHover
            : root.elementGrouped("bluetooth") || root.appearance.pillsTransparent
                || root.appearance.transparentBarSlanted ? "transparent" : theme.surface

        border.width: root.appearance.elementBorder && !root.elementGrouped("bluetooth") ? 1 : 0
        border.color: root.appearance.elementBorder ? theme.border : "transparent"

        Behavior on color {
            ColorAnimation { duration: root.appearance.motion.short }
        }

        HoverHandler {
            id: bluetoothHover
        }

        Text {
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

        readonly property var size: root.elementSize(root.appearance.workspaceButtonSize)

        visible: root.itemVisible("tray")
        x: root.elementX("tray")
        y: root.elementY("tray")
        width: size.width
        height: size.height
        radius: root.appearance.radius
        color: trayHover.hovered ? theme.surfaceHover
            : root.elementGrouped("tray") || root.appearance.pillsTransparent
                || root.appearance.transparentBarSlanted ? "transparent" : theme.surface

        border.width: root.appearance.elementBorder && !root.elementGrouped("tray") ? 1 : 0
        border.color: root.appearance.elementBorder ? theme.border : "transparent"

        Behavior on color {
            ColorAnimation { duration: root.appearance.motion.short }
        }

        HoverHandler {
            id: trayHover
        }

        Text {
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

        readonly property var size: root.elementSize(root.appearance.workspaceButtonSize)

        visible: root.itemVisible("network")
        x: root.elementX("network")
        y: root.elementY("network")
        width: size.width
        height: size.height
        radius: root.appearance.radius
        color: networkHover.hovered ? theme.surfaceHover
            : root.elementGrouped("network") || root.appearance.pillsTransparent
                || root.appearance.transparentBarSlanted ? "transparent" : theme.surface

        border.width: root.appearance.elementBorder && !root.elementGrouped("network") ? 1 : 0
        border.color: root.appearance.elementBorder ? theme.border : "transparent"

        Behavior on color {
            ColorAnimation { duration: root.appearance.motion.short }
        }

        HoverHandler {
            id: networkHover
        }

        Text {
            anchors.centerIn: parent
            text: root.networkIcon()
            color: theme.purple
            font.pixelSize: root.appearance.iconSize
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.popupRequested("network")
        }
    }

    Rectangle {
        id: batteryButton

        readonly property var size: root.sizeAround(batteryContent)

        visible: root.itemVisible("battery")
        x: root.elementX("battery")
        y: root.elementY("battery")
        width: size.width
        height: size.height
        radius: root.appearance.radius
        color: batteryHover.hovered ? theme.surfaceHover
            : root.elementGrouped("battery") || root.appearance.pillsTransparent
                || root.appearance.transparentBarSlanted ? "transparent" : theme.surface

        border.width: root.appearance.elementBorder && !root.elementGrouped("battery") ? 1 : 0
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
            iconSize: root.appearance.iconSize
            valueSize: root.appearance.textSize
            value: Math.round(root.battery.percentage * 100) + "%"
            valueVisible: BarProfileModel.elementOption(root.appearance.barElements, "battery", "percentageVisible")
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.popupRequested("battery")
        }
    }

    Rectangle {
        id: pomodoroButton

        readonly property var size: root.sizeAround(clockContent)

        visible: root.itemVisible("clock")
        x: root.elementX("clock")
        y: root.elementY("clock")
        width: size.width
        height: size.height
        radius: root.appearance.radius
        color: clockHover.hovered ? theme.surfaceHover
            : root.elementGrouped("clock") || root.appearance.pillsTransparent
                || root.appearance.transparentBarSlanted ? "transparent" : theme.surface

        border.width: root.appearance.elementBorder && !root.elementGrouped("clock") ? 1 : 0
        border.color: root.appearance.elementBorder ? theme.border : "transparent"

        Behavior on color {
            ColorAnimation { duration: root.appearance.motion.short }
        }

        HoverHandler {
            id: clockHover
        }

        ElementStack {
            id: clockContent

            anchors.centerIn: parent
            appearance: root.appearance
            spacing: sideBar && !root.pomodoro.started ? 0 : 7

            // Opens along the bar when a pomodoro starts.
            Item {
                id: pomodoroIndicator

                readonly property var openSize: BarLayout.size(root.appearance,
                    root.pomodoro.started
                        ? BarLayout.itemLength(root.appearance, { width: pomodoroText.implicitWidth, height: pomodoroText.implicitHeight })
                        : 0,
                    clockContent.sideBar ? pomodoroText.width : pomodoroText.implicitHeight)

                width: openSize.width
                height: openSize.height
                clip: true

                AlongBarBehavior on width { appearance: root.appearance }
                AlongBarBehavior on height { appearance: root.appearance }

                ElementText {
                    id: pomodoroText

                    anchors.verticalCenter: clockContent.sideBar ? undefined : parent.verticalCenter
                    appearance: root.appearance
                    value: "󰔟  " + root.pomodoro.remainingLabel
                    color: root.pomodoro.running ? theme.green : theme.textMuted
                    opacity: root.pomodoro.started ? 1 : 0
                    font.pixelSize: root.appearance.textSize
                    font.bold: true

                    Behavior on opacity {
                        NumberAnimation {
                            duration: root.appearance.motion.short
                            easing.type: root.appearance.motion.easing
                        }
                    }
                }
            }

            Clock {
                appearance: root.appearance
                color: theme.orange
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.popupRequested("pomodoro")
        }
    }
}
