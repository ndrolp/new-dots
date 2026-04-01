import { Gtk } from "ags/gtk4"
import { createBinding, createComputed, With } from "ags"
import type { Accessor } from "gnim"
import AstalNetwork from "gi://AstalNetwork"
import { WifiNetworkInfo } from "../../Network/components/NetworkInfo"
import { WirelessConectionManager } from "../../Network/components/WirelessConectionManager"

export function WifiSettings() {
  const network = AstalNetwork.get_default()
  const primaryNetwork = createBinding(network, "primary")

  return (
    <box
      class="qs-settings-panel"
      orientation={Gtk.Orientation.VERTICAL}
      spacing={8}
    >
      <With value={primaryNetwork}>
        {(primary) =>
          primary === AstalNetwork.Primary.WIFI ? (
            <WifiNetworkInfo network={network} />
          ) : (
            <></>
          )
        }
      </With>
      <WirelessConectionManager network={network} />
    </box>
  )
}

export function WifiTile({
  expanded,
  onToggleExpand,
}: {
  expanded: Accessor<boolean>
  onToggleExpand: () => void
}) {
  const network = AstalNetwork.get_default()
  const hasWifi = network.wifi !== null

  const primaryNetwork = createBinding(network, "primary")
  const wifiEnabled = hasWifi
    ? createBinding(network, "wifi", "enabled")
    : createComputed(() => false)
  const ssid = hasWifi
    ? createBinding(network, "wifi", "ssid")
    : createComputed(() => null)

  const data = createComputed(() => ({
    primary: primaryNetwork(),
    enabled: wifiEnabled(),
    ssid: ssid(),
  }))

  return (
    <With value={data}>
      {({ primary, enabled, ssid }) => {
        const active =
          enabled || primary === AstalNetwork.Primary.WIRED
        const icon =
          primary === AstalNetwork.Primary.WIRED
            ? "󰈀"
            : enabled
              ? "󰤨"
              : "󰤭"
        const detail =
          primary === AstalNetwork.Primary.WIRED
            ? "Wired"
            : enabled && ssid
              ? ssid
              : enabled
                ? "On"
                : "Off"

        return (
          <box class={`qs-tile ${active ? "active" : ""}`} spacing={0}>
            <button
              class="qs-tile-toggle"
              hexpand
              onClicked={() => {
                if (hasWifi) network.wifi.enabled = !network.wifi.enabled
              }}
              sensitive={hasWifi}
            >
              <box spacing={10} valign={Gtk.Align.CENTER}>
                <label class="tile-icon" label={icon} />
                <box
                  orientation={Gtk.Orientation.VERTICAL}
                  spacing={1}
                  halign={Gtk.Align.START}
                >
                  <label
                    class="tile-name"
                    label="Wi-Fi"
                    halign={Gtk.Align.START}
                  />
                  <label
                    class="tile-detail"
                    label={detail}
                    halign={Gtk.Align.START}
                    ellipsize={3}
                    maxWidthChars={10}
                  />
                </box>
              </box>
            </button>
            <button
              class="qs-tile-chevron"
              onClicked={onToggleExpand}
              valign={Gtk.Align.CENTER}
              tooltipText="Settings"
            >
              <With value={expanded}>
                {(open) => (
                  <label
                    class="tile-chevron"
                    label={open ? "󰅃" : "󰅀"}
                  />
                )}
              </With>
            </button>
          </box>
        )
      }}
    </With>
  )
}
