import AstalNetwork from "gi://AstalNetwork"
import NM from "gi://NM"

export function getWifiIcon(state: AstalNetwork.State, strength: number = 100) {
  let icon: string | undefined = undefined

  if (state === AstalNetwork.State.CONNECTED_GLOBAL) {
    icon = "󰤨"
  }

  if (
    state === AstalNetwork.State.CONNECTING ||
    state === AstalNetwork.State.DISCONNECTING
  ) {
    icon = ""
  }

  if (state === AstalNetwork.State.DISCONNECTED) {
    icon = "󰤭"
  }

  if (
    state === AstalNetwork.State.CONNECTED_LOCAL ||
    state === AstalNetwork.State.CONNECTED_SITE
  ) {
    icon = "󰤠"
  }

  return icon ?? "󰤨"
}

export function getEthernetIcon(state: AstalNetwork.State) {}
