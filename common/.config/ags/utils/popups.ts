import { SETTINGS } from "../config/Settings"
import { Astal, Gtk } from "ags/gtk4"
const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

export function getWindowMarginClass(anchor: Astal.WindowAnchor): string {
  let classToReturn = "top"
  if (anchor === (TOP | RIGHT)) return "top right"
  if (anchor === (TOP | LEFT)) return "top left"
  return classToReturn
}

export function getWindowAnchors(position: Gtk.Align): Astal.WindowAnchor {
  let anchorToReturn: Astal.WindowAnchor = TOP

  if (SETTINGS.barAppearence.island) anchorToReturn = TOP
  else {
    if (position === Gtk.Align.END) anchorToReturn = anchorToReturn | RIGHT
    if (position === Gtk.Align.START) anchorToReturn = anchorToReturn | LEFT
  }

  console.log({ anchorToReturn })
  return anchorToReturn
}
