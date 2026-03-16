export const ACTIVE_CLIENT_ICONS: Record<string, string> = {
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
  default: "",
  "google-chrome": "",
  nemo: "",
}

const terminals = [
  "alacritty",
  "kitty",
  "foot",
  "wezterm",
  "st",
  "xterm",
  "urxvt",
]

const terminalProgramsIcons: Record<string, string> = {
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

export function getActiveClientIcon(initialClass: string, title: string) {
  if (terminals.includes(initialClass.toLowerCase())) {
    return (
      terminalProgramsIcons[title.toLowerCase()] ||
      ACTIVE_CLIENT_ICONS[initialClass] ||
      ACTIVE_CLIENT_ICONS["terminal"]
    )
  }

  return (
    ACTIVE_CLIENT_ICONS[initialClass.toLowerCase()] ||
    ACTIVE_CLIENT_ICONS["default"]
  )
}
