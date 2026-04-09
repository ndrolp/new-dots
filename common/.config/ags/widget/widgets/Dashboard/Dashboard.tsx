import { Gtk } from "ags/gtk4"
import { createState, createComputed } from "ags"
import { WINDOWS_NAMESPACES } from "../../windows"
import { WifiTile, WifiSettings } from "./components/WifiPanel"
import { BluetoothTile, BluetoothSettings } from "./components/BluetoothPanel"
import { NotificationsPanel } from "./components/NotificationsPanel"
import { SystemTray } from "./components/SystemTray"
import { BrightnessSlider } from "./components/BrightnessSlider"
import CustomWindow from "../../common/Window"
import { getDashboardAlign } from "../../../utils/popups"

export default function Dashboard() {
  type Expanded = "wifi" | "bt" | null
  const [expanded, setExpanded] = createState<Expanded>(null)

  const wifiExpanded = createComputed(() => expanded() === "wifi")
  const btExpanded = createComputed(() => expanded() === "bt")

  const toggleWifi = () => setExpanded((e) => (e === "wifi" ? null : "wifi"))
  const toggleBt = () => setExpanded((e) => (e === "bt" ? null : "bt"))

  return (
    <CustomWindow
      name={WINDOWS_NAMESPACES.dashboard}
      namespace={WINDOWS_NAMESPACES.dashboard}
      position={getDashboardAlign()}
      css="nc-window"
      resizable={false}
    >
      <box class="nc-root" orientation={Gtk.Orientation.VERTICAL}>
        {/* Quick-setting tiles */}
        <box class="nc-tiles" spacing={8}>
          <WifiTile expanded={wifiExpanded} onToggleExpand={toggleWifi} />
          <BluetoothTile expanded={btExpanded} onToggleExpand={toggleBt} />
        </box>

        {/* Inline settings panels (slide in below tiles) */}
        <revealer
          transition_type={Gtk.RevealerTransitionType.SLIDE_DOWN}
          revealChild={wifiExpanded}
          transition_duration={200}
        >
          <box class="nc-settings-wrap">
            <WifiSettings />
          </box>
        </revealer>

        <revealer
          transition_type={Gtk.RevealerTransitionType.SLIDE_DOWN}
          revealChild={btExpanded}
          transition_duration={200}
        >
          <box class="nc-settings-wrap">
            <BluetoothSettings />
          </box>
        </revealer>

        {/* Brightness */}
        <box class="nc-brightness">
          <BrightnessSlider />
        </box>

        {/* Notifications — scrollable, shrinks when empty */}
        <scrolledwindow
          class="nc-scroll"
          hscrollbar_policy={Gtk.PolicyType.NEVER}
          vscrollbar_policy={Gtk.PolicyType.AUTOMATIC}
        >
          <box class="nc-scroll-inner" orientation={Gtk.Orientation.VERTICAL}>
            <NotificationsPanel />
          </box>
        </scrolledwindow>

        {/* System tray */}
        <box class="nc-tray-wrap">
          <SystemTray />
        </box>
      </box>
    </CustomWindow>
  )
}
