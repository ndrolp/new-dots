import AstalHyprland from "gi://AstalHyprland"
import { WallpapersBoxOrientation } from "../components/WallpapersBox"

export function buildRows<T>(items: T[], columns = 5): T[][] {
  const rows: T[][] = []

  items.forEach((item, i) => {
    const row = Math.floor(i / columns)

    if (!rows[row]) rows[row] = []
    rows[row].push(item)
  })

  return rows
}

export function getMonitorDirection(
  transform: AstalHyprland.MonitorTransform,
): WallpapersBoxOrientation {
  const horizontal = [
    AstalHyprland.MonitorTransform.NORMAL,
    AstalHyprland.MonitorTransform.ROTATE_180_DEG,
    AstalHyprland.MonitorTransform.FLIPPED,
    AstalHyprland.MonitorTransform.FLIPPED_ROTATE_180_DEG,
  ]

  return horizontal.includes(transform) ? "horizontal" : "vertical"
}
