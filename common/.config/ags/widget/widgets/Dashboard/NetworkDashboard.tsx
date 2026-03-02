import { SETTINGS } from "../../../config/Settings"
import { Gtk, Astal } from "ags/gtk4"
import app from "ags/gtk4/app"
import { WifiNetworkInfo } from "./components/NetworkInfo"
import { createBinding, createComputed, With } from "ags"
import AstalNetwork from "gi://AstalNetwork"
import { getWindowAnchors, getWindowMarginClass } from "../../../utils/popups"
import CustomWindow from "../../common/Window"

export const NETWORK_DASHBOARD_WINDOW_NAME = "networkdash"

export default function NetworkDashboard(
  position: Gtk.Align = Gtk.Align.CENTER,
) {
  const Network = AstalNetwork.get_default()

  const primaryNetwork = createBinding(Network, "primary")
  const isWifiEnabled = createBinding(Network, "wifi", "enabled")

  const networkDashboardData = createComputed(() => {
    return { primary: primaryNetwork(), wifiEnabled: isWifiEnabled() }
  })

  return (
    <CustomWindow
      name={NETWORK_DASHBOARD_WINDOW_NAME}
      namespace={NETWORK_DASHBOARD_WINDOW_NAME}
      position={position}
      css="network-dashboard"
    >
      <box>
        <With value={networkDashboardData}>
          {(data) => {
            return (
              <box>
                <box orientation={Gtk.Orientation.VERTICAL} spacing={5}>
                  {data.primary === AstalNetwork.Primary.WIFI ? (
                    <WifiNetworkInfo />
                  ) : data.primary === AstalNetwork.Primary.WIRED ? (
                    <label label="WIRED" />
                  ) : (
                    <box
                      class="card disconnected-card"
                      orientation={Gtk.Orientation.VERTICAL}
                      spacing={10}
                    >
                      <label
                        hexpand
                        label="󰯡"
                        class="network-icon"
                        halign={Gtk.Align.CENTER}
                      />
                      <label label="No network connected" />
                    </box>
                  )}
                </box>
              </box>
            )
          }}
        </With>
      </box>
    </CustomWindow>
  )
}
