import { ShellSettings } from "../../../utils/SettingsManager"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { WINDOWS_NAMESPACES } from "../../windows"

export default function Dashboard() {
  const { TOP, RIGHT, LEFT } = Astal.WindowAnchor
  const settings = ShellSettings.getInstance()
  return (
    <window
      name={WINDOWS_NAMESPACES.dashboard}
      class={`${settings.theme} window`}
      anchor={settings.barAppearence.island ? TOP : TOP | LEFT}
    >
      <box class="container">
        <label label={"Dashboard"} />
      </box>
    </window>
  )
}
