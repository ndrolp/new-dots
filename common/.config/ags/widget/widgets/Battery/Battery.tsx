import { Gtk } from "ags/gtk4"
import AstalBattery from "gi://AstalBattery"
import { createBinding, createComputed, With } from "ags"
import { getBatteryIcon } from "../../../utils/battery"
import app from "ags/gtk4/app"
import { BATTERY_DASHBOARD_WINDOW_NAME } from "./BatteryDashboard"
export default function Battery() {
  const battery = AstalBattery.get_default()

  const batteryPercentage = createBinding(battery, "percentage")
  const batteryState = createBinding(battery, "state")
  return (
    <button
      class="battery-dashboard-togler"
      onClicked={() => {
        app.toggle_window(BATTERY_DASHBOARD_WINDOW_NAME)
      }}
    >
      <box class="battery">
        <With value={batteryPercentage}>
          {(percentage) => (
            <box>
              <With value={batteryState}>
                {(state) => (
                  <box class=".blue-fg">
                    <label
                      margin_end={state === AstalBattery.State.CHARGING ? 8 : 5}
                      label={getBatteryIcon(state, percentage)}
                    />
                    <label
                      label={
                        parseInt((percentage * 100).toString()).toString() + "%"
                      }
                    />
                  </box>
                )}
              </With>
            </box>
          )}
        </With>
      </box>
    </button>
  )
}
