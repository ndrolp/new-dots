import { Gtk, Astal } from "ags/gtk4"
import { WifiNetworkInfo } from "./components/NetworkInfo"
import { createBinding, createComputed, With } from "ags"
import AstalNetwork from "gi://AstalNetwork"
import CustomWindow from "../../common/Window"
import { WirelessConectionManager } from "./components/WirelessConectionManager"
import { WINDOWS_NAMESPACES } from "../../windows"

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
      name={WINDOWS_NAMESPACES.network}
      namespace={WINDOWS_NAMESPACES.network}
      position={position}
      css="network-dashboard"
      onVisivilityChange={(self) => {
        if (!self.visible) return
        if (Network.primary === AstalNetwork.Primary.WIFI) {
          Network.wifi.scan()
        }
      }}
    >
      <box>
        <With value={networkDashboardData}>
          {(data) => {
            return (
              <box>
                <box orientation={Gtk.Orientation.VERTICAL} spacing={5}>
                  {data.primary === AstalNetwork.Primary.WIFI ? (
                    <WifiNetworkInfo network={Network} />
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
                  <box>
                    {data.wifiEnabled ? (
                      <WirelessConectionManager network={Network} />
                    ) : (
                      <></>
                    )}
                  </box>
                </box>
              </box>
            )
          }}
        </With>
      </box>
    </CustomWindow>
  )
}
