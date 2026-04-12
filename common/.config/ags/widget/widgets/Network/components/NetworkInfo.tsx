import { Gtk } from "ags/gtk4"
import { ShellSettings } from "../../../../utils/SettingsManager"
import AstalNetwork from "gi://AstalNetwork"
import { createBinding, createComputed, With } from "ags"
import {
  getDeviceIpAddress,
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

  const settings = ShellSettings.getInstance()

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
              class={`wifi-settings rounding-${settings.barAppearence.rounding} card`}
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
                    getDeviceIpAddress(data.device) ?? "Retrieving ip"
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
