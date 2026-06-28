.pragma library

.import "settings.js" as Settings

var ACTIVE_CLIENT_ICONS = {
  firefox: "",
  chromium: "",
  code: "󰨞",
  spotify: "",
  discord: "",
  slack: "",
  terminal: "",
  vscode: "",
  thunderbird: "",
  obsidian: "󰎚",
  kitty: "",
  nvim: "",
  "google-chrome": "",
  nemo: "",
  nautilus: "",
  Nautilus: "",
  "orgkgnome.Nautilus": "",
  default: "",
}

var TERMINALS = ["alacritty", "kitty", "foot", "wezterm", "st", "xterm", "urxvt"]

var TERMINAL_PROGRAM_ICONS = {
  htop: "",
  btm: "",
  nvim: "",
  "btop++": "",
  btop: "",
  lazygit: "",
  lazydocker: "",
  broot: "",
  nnn: "",
  ranger: "",
  vifm: "",
  bmon: "",
  bpytop: "",
  gotop: "",
  glances: "",
  bashtop: "",
  gdu: "",
  dust: "",
  dua: "",
  ncdu: "",
  cdu: "",
  vtop: "",
  procs: "",
  bandwhich: "",
  nload: "",
  ifstat: "",
  "iptraf-ng": "",
}

var PLAYER_ICONS = {
  spotify: "󰓇",
  chrome: "",
  chromium: "",
  vlc: "󰕼",
  default: "",
}

var CHROME_PLAY_ICONS = {
  youtube: "",
}

function getVolumeIcon(volume, muted) {
  if (muted) return ""
  if (volume <= 0) return ""
  return ""
}

function getVolumeBar(volume) {
  if (volume <= 0) return ""
  if (volume <= 0.1) return "▁"
  if (volume <= 0.2) return "▂"
  if (volume <= 0.3) return "▃"
  if (volume <= 0.5) return "▄"
  if (volume <= 0.6) return "▅"
  if (volume <= 0.7) return "▆"
  if (volume <= 0.8) return "▇"
  return "█"
}

function getBatteryIcon(stateName, percentage) {
  var charging = String(stateName).toLowerCase().indexOf("charging") >= 0
  var value = Number(percentage)

  if (charging) {
    if (value <= 0.1) return "󰢜"
    if (value <= 0.2) return "󰂆"
    if (value <= 0.3) return "󰂇"
    if (value <= 0.4) return "󰂈"
    if (value <= 0.5) return "󰢝"
    if (value <= 0.6) return "󰂉"
    if (value <= 0.7) return "󰢞"
    if (value <= 0.8) return "󰂊"
    if (value <= 0.9) return "󰂋"
    return "󰂅"
  }

  if (value <= 0.1) return "󰁺"
  if (value <= 0.2) return "󰁻"
  if (value <= 0.3) return "󰁼"
  if (value <= 0.4) return "󰁽"
  if (value <= 0.5) return "󰁾"
  if (value <= 0.6) return "󰁿"
  if (value <= 0.7) return "󰂀"
  if (value <= 0.8) return "󰂁"
  if (value <= 0.9) return "󰂂"
  return "󰁹"
}

function getActiveClientIcon(initialClass, title) {
  var normalizedClass = String(initialClass || "").toLowerCase()
  var normalizedTitle = String(title || "").toLowerCase()

  if (TERMINALS.indexOf(normalizedClass) >= 0) {
    return (
      TERMINAL_PROGRAM_ICONS[normalizedTitle] ||
      ACTIVE_CLIENT_ICONS[normalizedClass] ||
      ACTIVE_CLIENT_ICONS.terminal
    )
  }

  return ACTIVE_CLIENT_ICONS[normalizedClass] || ACTIVE_CLIENT_ICONS.default
}

function getPlayerIcon(identity, title) {
  var normalizedIdentity = String(identity || "").toLowerCase()
  var normalizedTitle = String(title || "").toLowerCase()
  var icon = PLAYER_ICONS.default
  var keys = Object.keys(PLAYER_ICONS)

  for (var i = 0; i < keys.length; i += 1) {
    var key = keys[i]
    if (normalizedIdentity.indexOf(key) >= 0) {
      icon = PLAYER_ICONS[key]
    }
  }

  if (normalizedIdentity.indexOf("chrome") >= 0 || normalizedIdentity.indexOf("chromium") >= 0) {
    var chromeKeys = Object.keys(CHROME_PLAY_ICONS)
    for (var j = 0; j < chromeKeys.length; j += 1) {
      var chromeKey = chromeKeys[j]
      if (normalizedTitle.indexOf(chromeKey) >= 0) {
        icon = CHROME_PLAY_ICONS[chromeKey]
      }
    }
  }

  return icon
}

function pickPlayer(players) {
  var usablePlayers = []
  var ignoreClients = Settings.SETTINGS.nowPlaying.ignoreClients
  var preferredClients = Settings.SETTINGS.nowPlaying.preferedClients

  for (var i = 0; i < players.length; i += 1) {
    var player = players[i]
    var id = String(player.desktopEntry || player.identity || "").toLowerCase()
    var title = String(player.trackTitle || "")

    if (!title) continue

    var ignored = false
    for (var j = 0; j < ignoreClients.length; j += 1) {
      if (id.indexOf(ignoreClients[j].toLowerCase()) >= 0) {
        ignored = true
        break
      }
    }

    if (!ignored) {
      usablePlayers.push(player)
    }
  }

  for (var preferredIndex = 0; preferredIndex < preferredClients.length; preferredIndex += 1) {
    var preferred = preferredClients[preferredIndex].toLowerCase()
    for (var playerIndex = 0; playerIndex < usablePlayers.length; playerIndex += 1) {
      var candidate = usablePlayers[playerIndex]
      var candidateId = String(candidate.desktopEntry || candidate.identity || "").toLowerCase()
      if (candidateId.indexOf(preferred) >= 0) {
        return candidate
      }
    }
  }

  return usablePlayers.length > 0 ? usablePlayers[0] : null
}
