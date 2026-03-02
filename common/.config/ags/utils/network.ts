import AstalNetwork from "gi://AstalNetwork"
import { createBinding, createComputed } from "ags"

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

export function getNetworkIconBinding() {
  const network = AstalNetwork.get_default()

  if (network.wifi !== null) {
    return createComputed(() => [
      createBinding(network, "connectivity"),
      createBinding(network.wifi, "strength"),
      createBinding(network, "primary"),
    ])(() => getNetworkIcon(network))
  } else {
    return createComputed(() => [
      createBinding(network, "connectivity"),
      createBinding(network, "primary"),
    ])(() => getNetworkIcon(network))
  }
}

export function getAccessPointIcon(accessPoint: AstalNetwork.AccessPoint) {
  const { strength, flags } = accessPoint

  // Based on Wi-Fi signal strength and internet status
  if (strength <= 25) {
    if (flags === 0) {
      return "󰤟"
    } else {
      return "󰤡"
    }
  } else if (strength <= 50) {
    if (flags === 0) {
      return "󰤢"
    } else {
      return "󰤤"
    }
  } else if (strength <= 75) {
    if (flags === 0) {
      return "󰤥"
    } else {
      return "󰤧"
    }
  } else {
    if (flags === 0) {
      return "󰤨"
    } else {
      return "󰤪"
    }
  }
}
export function getNetworkIcon(network: AstalNetwork.Network) {
  const { connectivity, wifi, wired, primary } = network

  // Handle wired connection
  if (primary === AstalNetwork.Primary.WIRED) {
    if (wired.internet === AstalNetwork.Internet.CONNECTED) {
      return "󰈀"
    } else {
      return "󰈀" // You could add more logic here for wired states if needed
    }
  }

  // Handle Wi-Fi connection
  if (primary === AstalNetwork.Primary.WIFI) {
    const { strength, internet, enabled } = wifi

    // If Wi-Fi is disabled or there is no connectivity
    if (!enabled || connectivity === AstalNetwork.Connectivity.NONE) {
      return "󰤭"
    }

    // Based on Wi-Fi signal strength and internet status
    if (strength <= 25) {
      if (internet === AstalNetwork.Internet.DISCONNECTED) {
        return "󰤠"
      } else if (internet === AstalNetwork.Internet.CONNECTED) {
        return "󰤟"
      } else if (internet === AstalNetwork.Internet.CONNECTING) {
        return "󰤡"
      }
    } else if (strength <= 50) {
      if (internet === AstalNetwork.Internet.DISCONNECTED) {
        return "󰤣"
      } else if (internet === AstalNetwork.Internet.CONNECTED) {
        return "󰤢"
      } else if (internet === AstalNetwork.Internet.CONNECTING) {
        return "󰤤"
      }
    } else if (strength <= 75) {
      if (internet === AstalNetwork.Internet.DISCONNECTED) {
        return "󰤦"
      } else if (internet === AstalNetwork.Internet.CONNECTED) {
        return "󰤥"
      } else if (internet === AstalNetwork.Internet.CONNECTING) {
        return "󰤧"
      }
    } else {
      if (internet === AstalNetwork.Internet.DISCONNECTED) {
        return "󰤩"
      } else if (internet === AstalNetwork.Internet.CONNECTED) {
        return "󰤨"
      } else if (internet === AstalNetwork.Internet.CONNECTING) {
        return "󰤪"
      }
    }

    // Fallback if none of the conditions are met
    return "󰤯"
  }

  // Default or unknown status
  return "󰤮"
}
