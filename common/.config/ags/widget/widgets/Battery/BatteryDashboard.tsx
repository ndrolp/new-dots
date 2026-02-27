import { Astal, Gtk } from "ags/gtk4"
import app from "ags/gtk4/app"

export const BATTERY_DASHBOARD_WINDOW_NAME = "battery"

export default function BatteryDashboard() {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible
      namespace={"battery-dashboard"}
      name={BATTERY_DASHBOARD_WINDOW_NAME}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      class={"Battery catppuccin"}
      anchor={TOP | RIGHT}
      marginRight={10}
      margin_top={10}
      application={app}
    >
      <box class="container" orientation={Gtk.Orientation.VERTICAL}>
        <label
          class="title"
          label="󰁹  Battery Info"
          halign={Gtk.Align.CENTER}
          hexpand
          margin_bottom={10}
        />
        <box class="battery-dashboard-percentage" hexpand>
          <slider hexpand value={0.5} min={0} max={1} />
          <label label="50%" />
        </box>
      </box>
    </window>
  )
}
