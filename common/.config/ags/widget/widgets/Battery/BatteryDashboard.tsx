import { Gtk } from "ags/gtk4"
import AstalBattery from "gi://AstalBattery"
import { createBinding, createState, With } from "ags"
import { execAsync } from "ags/process"
import { secondsToTime } from "../../../utils/battery"
import { getWindowSettingsCssClasses } from "../../../utils/mainBar"

//TODO: Remake this component

export default function BatteryDashboard({}: { position?: Gtk.Align }) {
  const battery = AstalBattery.get_default()

  const batteryPercentage = createBinding(battery, "percentage")
  const batteryDischargeTime = createBinding(battery, "timeToEmpty")
  const batteryChargeTime = createBinding(battery, "time_to_full")
  const batteryState = createBinding(battery, "state")
  const [isVisible, setIsVisible] = createState(false)
  const [batteryHealth, setBatteryHealth] = createState("Loading...")

  const refreshBatteryHealth = () => {
    execAsync([
      "sh",
      "-c",
      "battery=$(upower -e | awk '/battery/ { print; exit }'); [ -n \"$battery\" ] && upower -i \"$battery\" | awk -F: '/^[[:space:]]*capacity:/ { gsub(/^[[:space:]]+|[[:space:]]+$/, \"\", $2); print $2; exit }'",
    ])
      .then((health) => setBatteryHealth(health.trim() || "Unavailable"))
      .catch(() => setBatteryHealth("Unavailable"))
  }

  refreshBatteryHealth()

  return (
    <popover
      cascadePopdown
      name="asd"
      class={"window " + getWindowSettingsCssClasses()}
      cascade_popdown={true}
      hasArrow={false}
      onNotifyVisible={(a) => {
        setIsVisible(a.visible)
        if (a.visible) refreshBatteryHealth()
      }}
    >
      <revealer
        transition_type={Gtk.RevealerTransitionType.SLIDE_DOWN}
        revealChild={isVisible}
      >
        <box class="battery-popover" orientation={Gtk.Orientation.VERTICAL}>
          <box class="" orientation={Gtk.Orientation.VERTICAL}>
            <label
              class="title"
              label="󰁹  Battery Info"
              halign={Gtk.Align.CENTER}
              hexpand
              margin_bottom={10}
            />
            <box class="battery-dashboard-percentage" hexpand>
              <With value={batteryPercentage}>
                {(percentage) => (
                  <box>
                    <slider
                      hexpand
                      value={percentage}
                      min={0}
                      max={1}
                      canTarget={false}
                    />
                    <label
                      margin_start={5}
                      label={(percentage * 100).toFixed(0).toString() + "%"}
                    />
                  </box>
                )}
              </With>
            </box>
          </box>
          <box hexpand class="separator"></box>
          <box class="time">
            <With value={batteryState}>
              {(state) => {
                return (
                  <box>
                    {state === AstalBattery.State.DISCHARGING ? (
                      <box>
                        <With value={batteryDischargeTime}>
                          {(dischargeTime) => (
                            <box>
                              <label
                                hexpand
                                halign={Gtk.Align.START}
                                label="Remaining:"
                              />
                              <label
                                hexpand
                                marginStart={10}
                                halign={Gtk.Align.END}
                                label={secondsToTime(dischargeTime)}
                              />
                            </box>
                          )}
                        </With>
                      </box>
                    ) : (
                      <box>
                        <With value={batteryChargeTime}>
                          {(chargeTime) => (
                            <box>
                              <label
                                hexpand
                                halign={Gtk.Align.START}
                                label="Time to Full:"
                              />
                              <label
                                hexpand
                                halign={Gtk.Align.END}
                                label={secondsToTime(chargeTime)}
                              />
                            </box>
                          )}
                        </With>
                      </box>
                    )}
                  </box>
                )
              }}
            </With>
          </box>
          <With value={batteryHealth}>
            {(health) => (
              <box>
                <label hexpand halign={Gtk.Align.START} label="Health:" />
                <label
                  hexpand
                  marginStart={10}
                  halign={Gtk.Align.END}
                  label={health}
                />
              </box>
            )}
          </With>
        </box>
      </revealer>
    </popover>
  )
}
