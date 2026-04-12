import AstalNetwork from "gi://AstalNetwork"
import { getDeviceIpAddress, getWifiIcon } from "../../../utils/network"
import { createBinding, createComputed, With } from "ags"
import { ShellSettings } from "../../../utils/SettingsManager"

export default function NetworkButton() {
  const Network = AstalNetwork.get_default()
  const settings = ShellSettings.getInstance()

  const wifi = createBinding(Network, "wifi")
  const wired = createBinding(Network, "wired")
  const stateData = createBinding(Network, "state")
  const primary = createBinding(Network, "primary")

  const wirelessButtonData = createComputed(() => {
    return {
      wifi: wifi(),
      wired: wired(),
      state: stateData(),
      primary: primary(),
      verbose: settings.barAppearence.verbose,
    }
  })

  return (
    <box>
      <With value={wirelessButtonData}>
        {(data) => {
          const rotateClass =
            data.state === AstalNetwork.State.CONNECTING ||
            data.state === AstalNetwork.State.DISCONNECTING
              ? "rotate"
              : ""
          return (
            <menubutton class="network-button bar-icon">
              {data.primary === AstalNetwork.Primary.WIFI ? (
                <box>
                  <label
                    class={`network-icon ${rotateClass}`}
                    label={getWifiIcon(data.state, data.wifi.state)}
                  />
                  <label
                    visible={data.verbose && !!data.wifi?.ssid}
                    class="network-label"
                    label={data.wifi?.ssid ?? ""}
                    ellipsize={3}
                    maxWidthChars={16}
                  />
                </box>
              ) : data.primary === AstalNetwork.Primary.WIRED ? (
                <box>
                  <label class="network-icon" label="󰈀" />
                  <label
                    visible={data.verbose}
                    class="network-label"
                    label={getDeviceIpAddress(data.wired?.device) ?? "Wired"}
                    ellipsize={3}
                    maxWidthChars={16}
                  />
                </box>
              ) : (
                <label
                  class={`network-icon ${rotateClass}`}
                  label={getWifiIcon(AstalNetwork.State.DISCONNECTED, 0)}
                />
              )}
            </menubutton>
          )
        }}
      </With>
    </box>
  )
}
