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

  return anchorToReturn
}

/** Returns the horizontal alignment that matches where the dashboard button
 *  lives in the current bar layout (left → START, center → CENTER, right → END).
 *  This drives the popup anchor so the panel appears directly below the button. */
export function getDashboardAlign(): Gtk.Align {
  const settings = ShellSettings.getInstance()
  const { island, float } = settings.barAppearence

  const layout = !float
    ? (settings.widgets.flush ?? settings.widgets.default)
    : island
      ? (settings.widgets.island ?? settings.widgets.default)
      : settings.widgets.default

  const inLeft = layout.left?.some((group) => group.includes("dashboard"))
  const inRight = layout.right?.some((group) => group.includes("dashboard"))

  if (inLeft) return Gtk.Align.START
  if (inRight) return Gtk.Align.END
  return Gtk.Align.CENTER
}
