import AstalNetwork from "gi://AstalNetwork"
import { getWifiIcon } from "../../../utils/network"
import NM from "gi://NM"
import { createBinding, createComputed, With } from "ags"

export default function NetworkButton() {
  const Network = AstalNetwork.get_default()

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
    }
  })

  AstalNetwork.DeviceState.SECONDARIES
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
            <button class="network-button bar-icon">
              {data.primary === AstalNetwork.Primary.WIFI ? (
                <label
                  class={`network-icon ${rotateClass}`}
                  label={getWifiIcon(data.state, data.wifi.state)}
                />
              ) : data.primary === AstalNetwork.Primary.WIRED ? (
                "WIRED"
              ) : (
                <label
                  class={`network-icon ${rotateClass}`}
                  label={getWifiIcon(AstalNetwork.State.DISCONNECTED, 0)}
                />
              )}
            </button>
          )
        }}
      </With>
    </box>
  )
}
