import { Gtk, Astal } from "ags/gtk4"
import { SETTINGS } from "../../../../config/Settings"
import AstalNetwork from "gi://AstalNetwork"
import { createBinding, createComputed, With } from "ags"
import NM from "gi://NM"
import { getWifiIcon } from "../../../../utils/network"

export const WifiNetworkInfo = (props: {}) => {
  const Network = AstalNetwork.get_default()

  const wifiName = createBinding(Network, "wifi", "ssid")
  const wifiDevice = createBinding(Network, "wifi", "device")
  const wifiStrength = createBinding(Network, "wifi", "strength")
  const wifiState = createBinding(Network, "state")

  const wifiInfoData = createComputed(() => {
    return {
      networkName: wifiName(),
      device: wifiDevice(),
      strength: wifiStrength(),
      state: wifiState(),
    }
  })

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
                  label={getWifiIcon(data.state, 100)}
                  class={`network-icon ${rotateClass}`}
                  halign={Gtk.Align.CENTER}
                  yalign={Gtk.Align.CENTER}
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
