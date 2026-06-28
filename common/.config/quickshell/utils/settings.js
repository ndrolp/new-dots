.pragma library

var SETTINGS = {
  theme: "catppuccin",
  barAppearence: {
    layout: "default",
    position: "top",
    island: false,
    compact: true,
    verbose: true,
    rounding: "none",
    float: false,
    showBorder: false,
  },
  workspaces: {
    monitors: {
      "PHL 271V8": { minWorkspaces: 5, from: 1, to: 10 },
      "PHL 243V7": { minWorkspaces: 3, from: 11, to: 20 },
      "0x08D5": { minWorkspaces: 5, from: 1, to: 20 },
      "E2212F": { minWorkspaces: 3, from: 11, to: 20 },
      "Q27G42XE": { minWorkspaces: 5, from: 1, to: 10 },
      "ATNA40HQ01-0 ": { minWorkspaces: 5, from: 1, to: 10 },
    },
    displayType: "numbers",
    icons: {
      "1": "",
      "2": "",
      "3": "󰣆",
      "4": "",
      "5": "",
      "6": "",
      "7": "",
      "8": "",
      "9": "",
      "10": "",
      "11": "󰘚",
      "12": "󰭳",
      "13": "󰇀",
    },
  },
  nowPlaying: {
    showControls: false,
    preferedClients: ["spotify", "chrome", "chromium"],
    ignoreClients: ["plasma-browser-integration"],
  },
}

var DEFAULT_WORKSPACE_RANGE = { from: 1, to: 20, minWorkspaces: 5 }
var DEFAULT_TIMERS = [60 * 60, 45 * 60, 30 * 60]

function resolveWorkspaceConfig(screen, hyprMonitor) {
  var monitorEntries = SETTINGS.workspaces.monitors
  var keys = Object.keys(monitorEntries)
  var screenModel = screen && screen.model ? String(screen.model) : ""
  var monitorDescription = hyprMonitor && hyprMonitor.description
    ? String(hyprMonitor.description)
    : ""

  for (var i = 0; i < keys.length; i += 1) {
    var key = keys[i]
    if (
      (screenModel && screenModel.indexOf(key) >= 0) ||
      (monitorDescription && monitorDescription.indexOf(key) >= 0)
    ) {
      return monitorEntries[key]
    }
  }

  return DEFAULT_WORKSPACE_RANGE
}

function workspaceLabel(id) {
  if (SETTINGS.workspaces.displayType === "numbers") {
    return String(id)
  }

  if (
    SETTINGS.workspaces.displayType === "icons" ||
    SETTINGS.workspaces.displayType === "icons-filled"
  ) {
    return SETTINGS.workspaces.icons[String(id)] || "󰣆"
  }

  return ""
}
