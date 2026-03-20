import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import Workspaces from "./widgets/Workspaces/workspaces"
import Clock from "./widgets/Clock"
import Battery from "./widgets/Battery/Battery"
import AudioButton from "./widgets/Audio/Audio"
import NowPlaying from "./widgets/Audio/Playing"
import NetworkButton from "./widgets/Network/NetworkButton"
import { ShellSettings } from "../utils/SettingsManager"
import { getWindowSettingsCssClasses } from "../utils/mainBar"
import CurrentApp from "./widgets/CurrentApp/CurrentApp"
import Layout from "./common/Layout"
import { WINDOWS_NAMESPACES } from "./windows"

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const SETTINGS = ShellSettings.getInstance()
  const { TOP, LEFT, RIGHT, BOTTOM } = Astal.WindowAnchor

  const allowedBarNames = ["default", "separated-islands"]

  const spacing =
    !allowedBarNames.includes(SETTINGS.barAppearence.layout) &&
    SETTINGS.barAppearence.compact
      ? 5
      : 0

  const Container = ({
    children,
  }: {
    children: JSX.Element | Array<JSX.Element>
  }) => {
    if (SETTINGS.barAppearence.island) {
      return (
        <box halign={Gtk.Align.CENTER}>
          <box
            orientation={Gtk.Orientation.HORIZONTAL}
            cssName="centerbox"
            class="bar-content"
            spacing={spacing + 5}
          >
            {children}
          </box>
        </box>
      )
    }
    return (
      <centerbox cssName="centerbox" class="bar-content">
        {children}
      </centerbox>
    )
  }

  let barCss = getWindowSettingsCssClasses()

  // <box class="slant">
  //   <label label={""} />
  // </box>
  // <box class="slanta">
  //   <label label={""} />
  // </box>
  // <CurrentApp monitor={gdkmonitor} />

  return (
    <window
      visible
      name="bar"
      namespace={WINDOWS_NAMESPACES.bar}
      class={`Bar ${barCss}`}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={!SETTINGS.barAppearence.island ? TOP | LEFT | RIGHT : TOP}
      application={app}
    >
      <Container>
        <Layout monitor={gdkmonitor} />
      </Container>
    </window>
  )
}
