import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import Workspaces from "./widgets/workspaces/workspaces"
import Clock from "./widgets/Clock"
import Battery from "./widgets/Battery/Battery"
import AudioButton from "./widgets/Audio/Audio"
import NowPlaying from "./widgets/Audio/Playing"
import NetworkButton from "./widgets/Network/NetworkButton"
import { ShellSettings } from "../utils/SettingsManager"
import { getWindowSettingsCssClasses } from "../utils/mainBar"
import CurrentApp from "./widgets/CurrentApp/CurrentApp"

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
            spacing={spacing}
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

  return (
    <window
      visible
      name="bar"
      class={`Bar ${barCss}`}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={!SETTINGS.barAppearence.island ? TOP | LEFT | RIGHT : TOP}
      application={app}
    >
      <Container>
        <box $type="start" spacing={spacing} class="bar-section">
          <button class="bar-icon test">
            <label label="" />
          </button>
          <CurrentApp monitor={gdkmonitor} />
        </box>
        <box
          halign={Gtk.Align.CENTER}
          $type="center"
          spacing={spacing}
          class="bar-section"
        >
          <Workspaces monitor={gdkmonitor} />
        </box>
        <box
          halign={Gtk.Align.END}
          $type="end"
          spacing={spacing}
          class="bar-section"
        >
          <NowPlaying />
          <AudioButton />
          <NetworkButton />
          <Battery />
          <Clock />
        </box>
      </Container>
    </window>
  )
}
