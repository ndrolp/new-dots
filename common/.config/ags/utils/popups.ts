import { ShellSettings } from "./SettingsManager"
import { Astal, Gtk } from "ags/gtk4"
import { AVAILABLE_WIDGETS } from "../config/types"
const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor

export function getWindowMarginClass(
  anchor: Astal.WindowAnchor | undefined,
): string {
  if (anchor === undefined) return ""

  const vertical = (anchor & BOTTOM) === BOTTOM ? "bottom" : "top"
  const horizontal =
    (anchor & RIGHT) === RIGHT
      ? " right"
      : (anchor & LEFT) === LEFT
        ? " left"
        : ""

  return `${vertical}${horizontal}`
}

export function getWindowAnchors(
  position: Gtk.Align,
): Astal.WindowAnchor | undefined {
  const SETTINGS = ShellSettings.getInstance()
  let anchorToReturn: Astal.WindowAnchor =
    SETTINGS.barAppearence.position === "bottom" ? BOTTOM : TOP

  if (SETTINGS.barAppearence.island) return anchorToReturn
  else {
    if (position === Gtk.Align.END) anchorToReturn = anchorToReturn | RIGHT
    if (position === Gtk.Align.START) anchorToReturn = anchorToReturn | LEFT
  }

  return anchorToReturn
}

/** Returns the horizontal alignment that matches where the dashboard button
 *  lives in the current bar layout (left → START, center → CENTER, right → END).
 *  This drives the popup anchor so the panel appears directly below the button. */
export function getWidgetAlign(widget: AVAILABLE_WIDGETS): Gtk.Align {
  const settings = ShellSettings.getInstance()
  const { island, float } = settings.barAppearence

  const layout = !float
    ? (settings.widgets.flush ?? settings.widgets.default)
    : island
      ? (settings.widgets.island ?? settings.widgets.default)
      : settings.widgets.default

  const inLeft = layout.left?.some((group) => group.includes(widget))
  const inRight = layout.right?.some((group) => group.includes(widget))

  if (inLeft) return Gtk.Align.START
  if (inRight) return Gtk.Align.END
  return Gtk.Align.CENTER
}

export function getDashboardAlign(): Gtk.Align {
  return getWidgetAlign("dashboard")
}

export function getClockAlign(): Gtk.Align {
  return getWidgetAlign("clock")
}
