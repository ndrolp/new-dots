import { Gtk, Gdk, Astal } from "ags/gtk4"
import app from "ags/gtk4/app"
import { SETTINGS } from "../../config/Settings"
import { getWindowAnchors, getWindowMarginClass } from "../../utils/popups"

export interface CustomWindowProps {
  children: JSX.Element | Array<JSX.Element>
  namespace: string
  name: string
  exclusivity?: Astal.Exclusivity
  position: Gtk.Align
  css?: string
}

export default function CustomWindow({
  children,
  position,
  name,
  namespace,
  css = "",
}: CustomWindowProps) {
  const anchor = getWindowAnchors(position)
  const cssClass = getWindowMarginClass(anchor)

  return (
    <window
      application={app}
      name={name}
      keymode={Astal.Keymode.ON_DEMAND}
      namespace={namespace}
      class={`window 
          ${SETTINGS.theme ?? "catppuccin"} 
          layout-${SETTINGS.barAppearence.layout ?? "default"} 
          rounding-${SETTINGS.barAppearence.rounding} 
          ${SETTINGS.barAppearence.compact ? "compact" : ""} 
          ${css} ${getWindowMarginClass(anchor)} ${cssClass}`}
      anchor={anchor}
    >
      <Gtk.EventControllerKey
        onKeyPressed={({ widget }, keyval: number) => {
          if (keyval === Gdk.KEY_Escape) {
            widget.hide()
          }
        }}
      />
      {children}
    </window>
  )
}
