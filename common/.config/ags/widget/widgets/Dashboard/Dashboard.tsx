import { SETTINGS } from "../../../config/Settings"
import { Astal, Gtk, Gdk } from "ags/gtk4"

export default function Dashboard() {
  const { TOP, RIGHT, LEFT } = Astal.WindowAnchor
  return (
    <window
      class={`${SETTINGS.theme} window`}
      anchor={SETTINGS.island ? TOP : TOP | LEFT}
    >
      <box class="container">
        <label label={"Dashboard"} />
      </box>
    </window>
  )
}
