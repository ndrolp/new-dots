import { Astal, Gtk, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import AstalBattery from "gi://AstalBattery"
import { createBinding, With } from "ags"
import { secondsToTime } from "../../../utils/battery"
import CustomWindow from "../../common/Window"
import { WINDOWS_NAMESPACES } from "../../windows"

//TODO: Remake this component

export default function BatteryDashboard(position: Gtk.Align = Gtk.Align.END) {
  const battery = AstalBattery.get_default()

  const batteryPercentage = createBinding(battery, "percentage")
  const batteryDischargeTime = createBinding(battery, "timeToEmpty")
  const batteryChargeTime = createBinding(battery, "time_to_full")
  const batteryState = createBinding(battery, "state")

  return (
    <CustomWindow
      namespace={"dashboard"}
      name={WINDOWS_NAMESPACES.battery}
      exclusivity={Astal.Exclusivity.NORMAL}
      css={`Battery`}
      position={position}
    >
      <box orientation={Gtk.Orientation.VERTICAL}>
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
                    margin_start={10}
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
      </box>
    </CustomWindow>
  )
}
