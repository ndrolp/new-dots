import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Hyprland._Ipc
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

import QtQuick

import "../utils/icons.js" as Icons
import "../utils/settings.js" as Settings
import "../utils/theme.js" as Theme

PanelWindow {
  id: root

  required property var modelData
  readonly property var qsScreen: modelData

  readonly property var colors: Theme.theme(Settings.SETTINGS.theme)
  readonly property var appearance: Settings.SETTINGS.barAppearence
  readonly property var hyprMonitor: Hyprland.monitorFor(qsScreen)
  readonly property var workspaceConfig: Settings.resolveWorkspaceConfig(qsScreen, hyprMonitor)
  readonly property var activePlayer: Icons.pickPlayer(Mpris.players ? Mpris.players.values : [])
  readonly property var activeSink: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
    ? Pipewire.defaultAudioSink.audio
    : null
  readonly property var activeToplevelForScreen: {
    var candidate = Hyprland.activeToplevel
    if (!candidate || !hyprMonitor) return null
    return candidate.monitor === hyprMonitor ? candidate : null
  }
  readonly property bool shouldShowDesktop: !!hyprMonitor
    && Hyprland.focusedMonitor === hyprMonitor
    && !activeToplevelForScreen
  readonly property var currentAppClass: activeToplevelForScreen
    ? String(activeToplevelForScreen.lastIpcObject["class"] || "")
    : ""
  readonly property string currentAppTitle: activeToplevelForScreen
    ? String(activeToplevelForScreen.title || "Desktop")
    : "Desktop"
  readonly property var batteryDevice: UPower.displayDevice
  readonly property bool batteryVisible: !!batteryDevice && batteryDevice.isPresent
  readonly property int batteryPercent: batteryVisible ? Math.round(batteryDevice.percentage * 100) : 0
  readonly property string batteryStateName: batteryVisible
    ? UPowerDeviceState.toString(batteryDevice.state)
    : "Unknown"
  readonly property int volumePercent: activeSink ? Math.round(activeSink.volume * 100) : 0
  readonly property string clockLabel: Qt.formatTime(clock.date, "hh:mm")
  readonly property bool verbose: appearance.verbose
  readonly property int workspaceCount: workspaceConfig.to - workspaceConfig.from + 1

  property int timerPresetIndex: 0
  property int remainingSeconds: Settings.DEFAULT_TIMERS[0]
  property string timerState: "stopped"
  property bool timerPopupOpen: false

  screen: qsScreen
  color: "transparent"
  focusable: false
  aboveWindows: true
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: barContainer.implicitHeight + 16
  implicitWidth: appearance.island ? barContainer.implicitWidth + 20 : qsScreen.width
  implicitHeight: barContainer.implicitHeight + 16

  anchors {
    top: appearance.position === "top"
    bottom: appearance.position === "bottom"
    left: !appearance.island
    right: !appearance.island
  }

  margins {
    top: appearance.position === "top" ? 8 : 0
    bottom: appearance.position === "bottom" ? 8 : 0
    left: 10
    right: 10
  }

  function workspaceForId(workspaceId) {
    var workspaces = Hyprland.workspaces ? Hyprland.workspaces.values : []
    for (var index = 0; index < workspaces.length; index += 1) {
      var workspace = workspaces[index]
      if (workspace.id === workspaceId) return workspace
    }
    return null
  }

  function workspaceOccupied(workspaceId) {
    var toplevels = Hyprland.toplevels ? Hyprland.toplevels.values : []
    for (var index = 0; index < toplevels.length; index += 1) {
      var toplevel = toplevels[index]
      if (toplevel.workspace && toplevel.workspace.id === workspaceId) {
        return true
      }
    }
    return false
  }

  function shouldShowWorkspace(workspaceId) {
    return !!workspaceForId(workspaceId)
      || workspaceId < workspaceConfig.from + workspaceConfig.minWorkspaces
  }

  function workspaceTextColor(workspaceId) {
    var workspace = workspaceForId(workspaceId)
    if (workspace && workspace.focused) return colors.fgdark
    if (workspaceOccupied(workspaceId)) return colors.fg
    return colors.fg2
  }

  function workspaceBackground(workspaceId) {
    var workspace = workspaceForId(workspaceId)
    return workspace && workspace.focused ? colors.accent0 : "transparent"
  }

  function startTimer() {
    if (remainingSeconds <= 0) {
      remainingSeconds = Settings.DEFAULT_TIMERS[timerPresetIndex]
    }
    timerState = "running"
  }

  function pauseTimer() {
    timerState = "paused"
  }

  function stopTimer() {
    timerState = "stopped"
    remainingSeconds = Settings.DEFAULT_TIMERS[timerPresetIndex]
  }

  function selectPreset(index) {
    timerPresetIndex = Math.max(0, Math.min(index, Settings.DEFAULT_TIMERS.length - 1))
    if (timerState !== "running") {
      remainingSeconds = Settings.DEFAULT_TIMERS[timerPresetIndex]
    }
  }

  function startQuickTimer(seconds) {
    remainingSeconds = seconds
    timerState = "running"
  }

  function adjustTimer(deltaSeconds) {
    remainingSeconds = Math.max(0, remainingSeconds + deltaSeconds)
  }

  function toggleTimerPopup() {
    timerPopupOpen = !timerPopupOpen
  }

  function restartNotification() {
    notifyProcess.running = false
    notifyProcess.running = true
  }

  function networkSummary() {
    var devices = Networking.devices ? Networking.devices.values : []
    var wifiDevice = null
    var wiredDevice = null

    for (var index = 0; index < devices.length; index += 1) {
      var device = devices[index]
      var type = DeviceType.toString(device.type)

      if (type === "Wifi") {
        wifiDevice = device
      } else if (type === "Wired") {
        wiredDevice = device
      }
    }

    if (wifiDevice) {
      var networks = wifiDevice.networks ? wifiDevice.networks.values : []
      for (var wifiIndex = 0; wifiIndex < networks.length; wifiIndex += 1) {
        var network = networks[wifiIndex]
        if (network.connected) {
          return {
            kind: "wifi",
            icon: wifiStrengthIcon(network.signalStrength),
            label: String(network.name || "Wi-Fi"),
            color: colors.accent0,
          }
        }
      }

      if (
        wifiDevice.state === ConnectionState.Connecting
        || wifiDevice.state === ConnectionState.Disconnecting
      ) {
        return {
          kind: "wifi",
          icon: "",
          label: "Connecting",
          color: colors.accent0,
        }
      }
    }

    if (wiredDevice && wiredDevice.connected) {
      return {
        kind: "wired",
        icon: "󰈀",
        label: String(wiredDevice.address || "Ethernet"),
        color: colors.accent0,
      }
    }

    if (wifiDevice) {
      return {
        kind: "wifi",
        icon: "󰤭",
        label: "Offline",
        color: colors.accent0,
      }
    }

    if (wiredDevice) {
      return {
        kind: "wired",
        icon: "󰈀",
        label: "Wired",
        color: colors.accent0,
      }
    }

    return {
      kind: "none",
      icon: "󰤮",
      label: "Offline",
      color: colors.accent0,
    }
  }

  function wifiStrengthIcon(strength) {
    if (strength <= 25) return "󰤟"
    if (strength <= 50) return "󰤢"
    if (strength <= 75) return "󰤥"
    return "󰤨"
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.timerState === "running"

    onTriggered: {
      root.remainingSeconds = Math.max(0, root.remainingSeconds - 1)

      if (root.remainingSeconds === 0) {
        root.timerState = "stopped"
        root.remainingSeconds = Settings.DEFAULT_TIMERS[root.timerPresetIndex]
        root.restartNotification()
      }
    }
  }

  Process {
    id: notifyProcess
    running: false
    command: [
      "notify-send",
      "Timer Finished",
      "Your timer has ended.",
      "-t",
      "5000",
      "-a",
      "QuickShell Timer",
    ]
  }

  Rectangle {
    id: barContainer

    anchors.top: parent.top
    anchors.topMargin: appearance.position === "top" ? 0 : 8
    anchors.bottom: parent.bottom
    anchors.bottomMargin: appearance.position === "bottom" ? 0 : 8
    anchors.horizontalCenter: parent.horizontalCenter

    color: colors.bg0
    border.width: appearance.showBorder ? 1 : 0
    border.color: colors.border0
    radius: appearance.rounding === "full" ? height / 2 : 10
    implicitWidth: barContent.implicitWidth + 10
    implicitHeight: barContent.implicitHeight + 10
    width: appearance.island ? implicitWidth : parent.width - 20

    Row {
      id: barContent

      anchors.centerIn: parent
      spacing: 10

      Row {
        spacing: 5

        ClockChip {
          colors: root.colors
          label: root.clockLabel
        }

        CurrentAppChip {
          colors: root.colors
          appClass: root.currentAppClass
          title: root.currentAppTitle
          active: root.activeToplevelForScreen || root.shouldShowDesktop
        }
      }

      Row {
        spacing: 5

        DashboardChip {
          colors: root.colors
        }

        WorkspacesChip {
          colors: root.colors
          workspaceConfig: root.workspaceConfig
          workspaceCount: root.workspaceCount
          shouldShowWorkspace: root.shouldShowWorkspace
          workspaceBackground: root.workspaceBackground
          workspaceTextColor: root.workspaceTextColor
        }

        TimerChip {
          id: timerChip
          colors: root.colors
          timerState: root.timerState
          remainingSeconds: root.remainingSeconds
          onClicked: root.toggleTimerPopup()
        }
      }

      Row {
        spacing: 5

        NowPlayingChip {
          colors: root.colors
          player: root.activePlayer
        }

        AudioChip {
          colors: root.colors
          activeSink: root.activeSink
          verbose: root.verbose
          volumePercent: root.volumePercent
        }

        NetworkChip {
          colors: root.colors
          verbose: root.verbose
          summary: root.networkSummary()
        }

        BatteryChip {
          colors: root.colors
          verbose: root.verbose
          batteryVisible: root.batteryVisible
          batteryDevice: root.batteryDevice
          batteryStateName: root.batteryStateName
          batteryPercent: root.batteryPercent
        }
      }
    }
  }

  TimerPopup {
    anchorWindow: root
    barContainer: barContainer
    anchorTarget: timerChip
    colors: root.colors
    position: root.appearance.position
    open: root.timerPopupOpen
    remainingSeconds: root.remainingSeconds
    timerPresetIndex: root.timerPresetIndex
    timerState: root.timerState
    onDismissed: root.timerPopupOpen = false
    onSelectPresetRequested: index => root.selectPreset(index)
    onStartQuickTimerRequested: seconds => root.startQuickTimer(seconds)
    onAdjustTimerRequested: delta => root.adjustTimer(delta)
    onStopTimerRequested: root.stopTimer()
    onPauseTimerRequested: root.pauseTimer()
    onStartTimerRequested: root.startTimer()
  }
}
