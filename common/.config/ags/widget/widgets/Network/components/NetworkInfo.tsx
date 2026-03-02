import { Gtk } from "ags/gtk4"
import { SETTINGS } from "../../../../config/Settings"
import AstalNetwork from "gi://AstalNetwork"
import { createBinding, createComputed, With } from "ags"
import {
  getNetworkIcon,
  getNetworkIconBinding,
} from "../../../../utils/network"

export const WifiNetworkInfo = ({
  network = AstalNetwork.get_default(),
}: {
  network?: AstalNetwork.Network
}) => {
  const wifiName = createBinding(network, "wifi", "ssid")
  const wifiDevice = createBinding(network, "wifi", "device")
  const wifiStrength = createBinding(network, "wifi", "strength")
  const wifiState = createBinding(network, "state")

  const wifiInfoData = createComputed(() => {
    return {
      networkName: wifiName(),
      device: wifiDevice(),
      strength: wifiStrength(),
      state: wifiState(),
      networkBind: getNetworkIconBinding(),
    }
  })

  // label={getWifiIcon(data.state, 100)}
  return (
    <box>
      <With value={wifiInfoData}>
        {(data) => {
          const rotateClass =
            data.state === AstalNetwork.State.CONNECTING ||
            data.state === AstalNetwork.State.DISCONNECTING
              ? "rotate"
              : ""

          return (
            <box
              class={`wifi-settings rounding-${SETTINGS.barAppearence.rounding} card`}
              hexpand
            >
              <box hexpand>
                <label
                  label={getNetworkIconBinding()}
                  class={`network-icon `}
                  halign={Gtk.Align.CENTER}
                />
              </box>
              <box
                orientation={Gtk.Orientation.VERTICAL}
                hexpand
                class="network-info-status"
                halign={Gtk.Align.END}
              >
                <label
                  label={data.networkName}
                  hexpand
                  halign={Gtk.Align.END}
                />
                <label
                  label={
                    data.device.get_dhcp4_config()?.get_options()?.ip_address ??
                    "Retrieving ip"
                  }
                  hexpand
                  halign={Gtk.Align.END}
                />
                <label label="" />
                <label
                  label={`Strength: ${data.strength}%`}
                  hexpand
                  halign={Gtk.Align.END}
                />
              </box>
            </box>
          )
        }}
      </With>
    </box>
  )
}
