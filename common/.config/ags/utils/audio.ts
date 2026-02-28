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
