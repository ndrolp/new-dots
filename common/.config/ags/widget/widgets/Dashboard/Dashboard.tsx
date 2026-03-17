import { ShellSettings } from "../../../utils/SettingsManager"
import { Astal, Gtk, Gdk } from "ags/gtk4"

export const DASHBOARD_WINDOW_NAME = "dashboard"

export default function Dashboard() {
  const { TOP, RIGHT, LEFT } = Astal.WindowAnchor
  const settings = ShellSettings.getInstance()
  return (
    <window
      name={DASHBOARD_WINDOW_NAME}
      class={`${settings.theme} window`}
      anchor={settings.barAppearence.island ? TOP : TOP | LEFT}
    >
      <box class="container">
        <label label={"Dashboard"} />
      </box>
    </window>
  )
}
