import AstalBattery from "gi://AstalBattery"
import { createBinding, With } from "ags"
import { getBatteryIcon } from "../../../utils/battery"
import { ShellSettings } from "../../../utils/SettingsManager"
import BatteryDashboard from "./BatteryDashboard"

export default function Battery() {
  const battery = AstalBattery.get_default()
  const settings = ShellSettings.getInstance()

  const batteryPercentage = createBinding(battery, "percentage")
  const batteryState = createBinding(battery, "state")
  return (
    <menubutton class="battery-dashboard-togler bar-icon">
      <box class="battery">
        <With value={batteryPercentage}>
          {(percentage) => (
            <box>
              <With value={batteryState}>
                {(state) => (
                  <box class=".blue-fg">
                    <label
                      margin_end={state === AstalBattery.State.CHARGING ? 0 : 0}
                      label={getBatteryIcon(state, percentage)}
                    />
                    <label
                      visible={settings.barAppearence.verbose}
                      label={`${Math.round(percentage * 100)}%`}
                    />
                  </box>
                )}
              </With>
            </box>
          )}
        </With>
      </box>
      <BatteryDashboard />
    </menubutton>
  )
}
