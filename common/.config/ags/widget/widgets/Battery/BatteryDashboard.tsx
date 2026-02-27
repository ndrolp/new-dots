import { Astal } from "ags/gtk4"
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
      application={app}
    >
      <box class="container">
        <label label="Dashboard" />
      </box>
    </window>
  )
}
