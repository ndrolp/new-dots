import { Gtk } from "ags/gtk4"
import { createBinding, createComputed, With } from "ags"
import type { Accessor } from "gnim"
import AstalBluetooth from "gi://AstalBluetooth"

function getBtDeviceIcon(iconName: string): string {
  const iconMap: Record<string, string> = {
    phone: "󰄜",
    "audio-headset": "󰋋",
    "audio-headphones": "󰋋",
    "audio-card": "󰓃",
    "input-keyboard": "󰌌",
    "input-mouse": "󰍽",
    computer: "󰌢",
    printer: "󰐪",
  }
  return iconMap[iconName] ?? "󰂱"
}

function BtDeviceRow({ device }: { device: AstalBluetooth.Device }) {
  const connected = createBinding(device, "connected")
  const connecting = createBinding(device, "connecting")
  const batteryPct = createBinding(device, "battery_percentage")
  const state = createComputed(() => ({
    connected: connected(),
    connecting: connecting(),
    battery: batteryPct(),
  }))

  return (
    <box class="bt-device-row" spacing={8} hexpand>
      <label
        class="bt-device-icon"
        label={getBtDeviceIcon(device.icon ?? "")}
        valign={Gtk.Align.CENTER}
      />
      <box
        orientation={Gtk.Orientation.VERTICAL}
        hexpand
        halign={Gtk.Align.START}
        valign={Gtk.Align.CENTER}
        spacing={1}
      >
        <label
          class="bt-device-name"
          label={device.name ?? "Unknown"}
          halign={Gtk.Align.START}
          ellipsize={3}
          maxWidthChars={16}
        />
        <With value={batteryPct}>
          {(pct) =>
            pct >= 0 ? (
              <label
                class="bt-device-battery"
                label={`${Math.round(pct * 100)}%`}
                halign={Gtk.Align.START}
              />
            ) : (
              <box />
            )
          }
        </With>
      </box>
      <With value={state}>
        {({ connected, connecting }) => (
          <button
            class={`bt-connect-btn ${connected ? "connected" : ""}`}
            sensitive={!connecting}
            onClicked={() =>
              connected ? device.disconnect_device() : device.connect_device()
            }
            valign={Gtk.Align.CENTER}
            tooltipText={connected ? "Disconnect" : "Connect"}
          >
            <label
              class={connecting ? "rotate" : ""}
              label={connecting ? "" : connected ? "󰂯" : "󰂲"}
            />
          </button>
        )}
      </With>
    </box>
  )
}

export function BluetoothSettings() {
  const bluetooth = AstalBluetooth.get_default()
  const devices = createBinding(bluetooth, "devices")

  return (
    <box
      class="qs-settings-panel"
      orientation={Gtk.Orientation.VERTICAL}
      spacing={6}
    >
      <With value={devices}>
        {(devs) => {
          const paired = devs.filter((d) => d.paired)
          if (paired.length === 0)
            return (
              <label
                class="qs-empty"
                label="No paired devices"
                halign={Gtk.Align.CENTER}
                hexpand
              />
            )
          return (
            <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
              {paired.map((d) => (
                <BtDeviceRow device={d} />
              ))}
            </box>
          )
        }}
      </With>
    </box>
  )
}

export function BluetoothTile({
  expanded,
  onToggleExpand,
}: {
  expanded: Accessor<boolean>
  onToggleExpand: () => void
}) {
  const bluetooth = AstalBluetooth.get_default()
  const isPowered = createBinding(bluetooth, "is_powered")
  const devices = createBinding(bluetooth, "devices")

  const data = createComputed(() => {
    const powered = isPowered()
    const connected = devices().filter((d) => d.connected)
    return {
      powered,
      detail: !powered
        ? "Off"
        : connected.length > 0
          ? (connected[0].name ?? "Connected")
          : "On",
    }
  })

  return (
    <With value={data}>
      {({ powered, detail }) => (
        <box class={`qs-tile ${powered ? "active" : ""}`} spacing={0}>
          <button
            class="qs-tile-toggle"
            hexpand
            onClicked={() => {
              bluetooth.is_powered = !bluetooth.is_powered
            }}
          >
            <box spacing={10} valign={Gtk.Align.CENTER}>
              <label class="tile-icon" label={powered ? "󰂯" : "󰂲"} />
              <box
                orientation={Gtk.Orientation.VERTICAL}
                spacing={1}
                halign={Gtk.Align.START}
              >
                <label
                  class="tile-name"
                  label="Bluetooth"
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
                <label class="tile-chevron" label={open ? "󰅃" : "󰅀"} />
              )}
            </With>
          </button>
        </box>
      )}
    </With>
  )
}
