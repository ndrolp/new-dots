import { ShellSettings } from "./SettingsManager"
import { Astal, Gtk } from "ags/gtk4"
const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

export function getWindowMarginClass(
  anchor: Astal.WindowAnchor | undefined,
): string {
  let classToReturn = "top"
  if (anchor === undefined) return ""
  if (anchor === (TOP | RIGHT)) return "top right"
  if (anchor === (TOP | LEFT)) return "top left"
  return classToReturn
}

export function getWindowAnchors(
  position: Gtk.Align,
): Astal.WindowAnchor | undefined {
  const SETTINGS = ShellSettings.getInstance()
  let anchorToReturn: Astal.WindowAnchor = TOP

  if (SETTINGS.barAppearence.island) anchorToReturn = TOP
  else {
    if (position === Gtk.Align.END) anchorToReturn = anchorToReturn | RIGHT
    if (position === Gtk.Align.START) anchorToReturn = anchorToReturn | LEFT
  }

  if (position === Gtk.Align.CENTER) return undefined

  return anchorToReturn
}
