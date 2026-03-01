import Mpris from "gi://AstalMpris"
import { SETTINGS } from "../config/Settings"
import { createBinding, createComputed, createState, With } from "ags"

export function getVolumeIcon(volume: number, muted: boolean): string {
  const test = "▁▂▃▄▅▆▇█"
  if (muted) return ""
  if (volume === 0) return ""
  return ""
}

export function getVolumeBar(volume: number): string {
  if (volume == 0) return ""
  if (volume <= 0.1) return "▁"
  if (volume <= 0.2) return "▂"
  if (volume <= 0.3) return "▃"
  if (volume <= 0.4) return "▄"
  if (volume <= 0.5) return "▄"
  if (volume <= 0.6) return "▅"
  else if (volume <= 0.7) return "▆"
  else if (volume <= 0.8) return "▇"
  else return "█"
}

const CHROME_PLAY_ICONS: Record<string, string> = {
  youtube: "",
}

const APP_ICONS: Record<string, string> = {
  spotify: "󰓇",
  chrome: "",
  vlc: "󰕼",
  default: "",
}

export function getPlayerIcon(identity: string, title: string): string {
  let icon = APP_ICONS.default

  for (const [key, value] of Object.entries(APP_ICONS)) {
    if (identity.toLowerCase().includes(key.toLowerCase())) icon = value
  }

  if (identity.toLowerCase().includes("chrome")) {
    Object.keys(CHROME_PLAY_ICONS).forEach((program) => {
      if (title.toLowerCase().includes(program))
        icon = CHROME_PLAY_ICONS[program]
      return
    })
  }

  return icon
}
