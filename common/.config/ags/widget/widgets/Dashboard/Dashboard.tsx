import { SETTINGS } from "../../../config/Settings"
import { Astal, Gtk, Gdk } from "ags/gtk4"

export const DASHBOARD_WINDOW_NAME = "dashboard"

export default function Dashboard() {
  const { TOP, RIGHT, LEFT } = Astal.WindowAnchor
  return (
    <window
      name={DASHBOARD_WINDOW_NAME}
      class={`${SETTINGS.theme} window`}
      anchor={SETTINGS.island ? TOP : TOP | LEFT}
    >
      <box class="container">
        <label label={"Dashboard"} />
      </box>
    </window>
  )
}
