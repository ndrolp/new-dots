import AstalBluetooth from "gi://AstalBluetooth"
import AstalNetwork from "gi://AstalNetwork"
import { createBinding, createComputed, createState, For } from "ags"
import { Gtk } from "ags/gtk4"
import type { Accessor } from "gnim"
import PopUp from "../../common/PopUp"
import { getAccessPointIcon } from "../../../utils/network"

function WifiNetworkRow({
  accessPoint,
  activeAccessPoint,
}: {
  accessPoint: AstalNetwork.AccessPoint
  activeAccessPoint: Accessor<AstalNetwork.AccessPoint>
}) {
  const strength = createBinding(accessPoint, "strength")
  const ssid = createBinding(accessPoint, "ssid")
  const requiresPassword = createBinding(accessPoint, "requiresPassword")
  const [showPassword, setShowPassword] = createState(false)
  const [password, setPassword] = createState("")

  const connect = () => {
    if (requiresPassword()) {
      accessPoint.activate(password())
    } else {
      accessPoint.activate()
    }
  }

  return (
    <box
      class="network-popup-access-point"
      orientation={Gtk.Orientation.VERTICAL}
    >
      <button
        class={createComputed(
          () =>
            `network-popup-row ${activeAccessPoint() === accessPoint ? "wifi-active" : ""}`,
        )}
        onClicked={() => {
          if (requiresPassword()) setShowPassword(!showPassword())
          else connect()
        }}
      >
        <box spacing={10}>
          <label
            class="network-popup-row-icon"
            label={createComputed(() => getAccessPointIcon(accessPoint))}
          />
          <label
            class="network-popup-row-name"
            hexpand
            halign={Gtk.Align.START}
            label={createComputed(() => ssid() || "Hidden network")}
            ellipsize={3}
            maxWidthChars={24}
          />
          <label
            class="network-popup-row-detail"
            label={createComputed(() =>
              requiresPassword() ? "󰌾" : `${Math.round(strength())}%`,
            )}
          />
        </box>
      </button>
      <revealer
        transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
        transitionDuration={200}
        revealChild={showPassword}
      >
        <box class="network-popup-password" spacing={8}>
          <entry
            hexpand
            placeholderText="Network password"
            visibility={false}
            $={(self) => {
              self.connect("changed", () => setPassword(self.get_text()))
            }}
          />
          <button
            class="network-popup-connect"
            sensitive={createComputed(() => password().length > 0)}
            onClicked={connect}
          >
            <label label="Connect" />
          </button>
        </box>
      </revealer>
    </box>
  )
}

function BluetoothDeviceRow({ device }: { device: AstalBluetooth.Device }) {
  const connected = createBinding(device, "connected")
  const connecting = createBinding(device, "connecting")
  const paired = createBinding(device, "paired")

  return (
    <button
      class={createComputed(
        () => `network-popup-row ${connected() ? "bluetooth-active" : ""}`,
      )}
      visible={paired}
      sensitive={createComputed(() => !connecting())}
      tooltipText={createComputed(() =>
        connected() ? "Disconnect" : "Connect",
      )}
      onClicked={() =>
        connected() ? device.disconnect_device() : device.connect_device()
      }
    >
      <box spacing={10}>
        <label class="network-popup-row-icon" label="󰂯" />
        <label
          class="network-popup-row-name"
          hexpand
          halign={Gtk.Align.START}
          label={device.name ?? "Unknown device"}
          ellipsize={3}
          maxWidthChars={24}
        />
        <label
          class="network-popup-row-detail"
          label={createComputed(() =>
            connecting() ? "󰑓" : connected() ? "󰄬" : "",
          )}
        />
      </box>
    </button>
  )
}

function WifiPanel({ network }: { network: AstalNetwork.Network }) {
  const wifi = network.wifi
  const enabled = createBinding(wifi, "enabled")
  const accessPoints = createBinding(wifi, "accessPoints")
  const activeAccessPoint = createBinding(wifi, "activeAccessPoint")

  return (
    <box
      class="network-popup-section"
      orientation={Gtk.Orientation.VERTICAL}
      spacing={8}
    >
      <box class="network-popup-section-header" spacing={10}>
        <label class="network-popup-section-icon" label="󰤨" />
        <label
          class="network-popup-section-title"
          hexpand
          halign={Gtk.Align.START}
          label="Wi-Fi"
        />
        <button
          class={createComputed(
            () => `network-popup-toggle ${enabled() ? "active" : ""}`,
          )}
          onClicked={() => {
            wifi.enabled = !enabled()
            if (!enabled()) wifi.scan()
          }}
        >
          <label label={createComputed(() => (enabled() ? "On" : "Off"))} />
        </button>
        <button
          class="network-popup-action"
          sensitive={enabled}
          tooltipText="Scan for networks"
          onClicked={() => wifi.scan()}
        >
          <label label="󰑐" />
        </button>
      </box>
      <revealer
        transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
        transitionDuration={250}
        revealChild={enabled}
      >
        <box
          class="network-popup-list"
          orientation={Gtk.Orientation.VERTICAL}
          spacing={6}
        >
          <For each={accessPoints}>
            {(accessPoint) => (
              <WifiNetworkRow
                accessPoint={accessPoint}
                activeAccessPoint={activeAccessPoint}
              />
            )}
          </For>
        </box>
      </revealer>
    </box>
  )
}

function BluetoothPanel() {
  const bluetooth = AstalBluetooth.get_default()
  const adapter = bluetooth.adapter
  const powered = createBinding(adapter, "powered")
  const devices = createBinding(bluetooth, "devices")
  const discovering = createBinding(adapter, "discovering")

  return (
    <box
      class="network-popup-section"
      orientation={Gtk.Orientation.VERTICAL}
      spacing={8}
    >
      <box class="network-popup-section-header" spacing={10}>
        <label class="network-popup-section-icon" label="󰂯" />
        <label
          class="network-popup-section-title"
          hexpand
          halign={Gtk.Align.START}
          label="Bluetooth"
        />
        <button
          class={createComputed(
            () => `network-popup-toggle ${powered() ? "active" : ""}`,
          )}
          onClicked={() => {
            adapter.powered = !powered()
          }}
        >
          <label label={createComputed(() => (powered() ? "On" : "Off"))} />
        </button>
        <button
          class={createComputed(
            () => `network-popup-action ${discovering() ? "scanning" : ""}`,
          )}
          sensitive={powered}
          tooltipText={createComputed(() =>
            discovering() ? "Stop device discovery" : "Scan for devices",
          )}
          onClicked={() => {
            if (discovering()) adapter.stop_discovery()
            else adapter.start_discovery()
          }}
        >
          <label label="󰑐" />
        </button>
      </box>
      <revealer
        transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
        transitionDuration={250}
        revealChild={powered}
      >
        <box
          class="network-popup-list"
          orientation={Gtk.Orientation.VERTICAL}
          spacing={6}
        >
          <For each={devices}>
            {(device) => <BluetoothDeviceRow device={device} />}
          </For>
        </box>
      </revealer>
    </box>
  )
}

export default function NetworkPopup() {
  const network = AstalNetwork.get_default()
  const [tab, setTab] = createState<"wifi" | "bluetooth">("wifi")
  const wifiActive = createComputed(() => tab() === "wifi")
  const bluetoothActive = createComputed(() => tab() === "bluetooth")

  return (
    <PopUp cssClass="network-popup" transitionDuration={400}>
      <box orientation={Gtk.Orientation.VERTICAL} spacing={16}>
        <box class="network-popup-tabs" spacing={8}>
          <button
            class={createComputed(
              () => `network-popup-tab ${wifiActive() ? "active" : ""}`,
            )}
            hexpand
            onClicked={() => setTab("wifi")}
          >
            <label label="󰤨  Wi-Fi" />
          </button>
          <button
            class={createComputed(
              () => `network-popup-tab ${bluetoothActive() ? "active" : ""}`,
            )}
            hexpand
            onClicked={() => setTab("bluetooth")}
          >
            <label label="󰂯  Bluetooth" />
          </button>
        </box>
        <revealer
          transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
          transitionDuration={250}
          revealChild={wifiActive}
        >
          <WifiPanel network={network} />
        </revealer>
        <revealer
          transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
          transitionDuration={250}
          revealChild={bluetoothActive}
        >
          <BluetoothPanel />
        </revealer>
      </box>
    </PopUp>
  )
}
