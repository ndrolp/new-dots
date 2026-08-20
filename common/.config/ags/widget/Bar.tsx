import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { ShellSettings } from "../utils/SettingsManager"
import { getWindowSettingsCssClasses } from "../utils/mainBar"
import Layout from "./common/Layout"
import { WINDOWS_NAMESPACES } from "./windows"
import { SettingsWidget } from "./widgets/Settings/SettingsWidget"

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const SETTINGS = ShellSettings.getInstance()
  const { TOP, LEFT, RIGHT, BOTTOM } = Astal.WindowAnchor
  const verticalAnchor =
    SETTINGS.barAppearence.position === "bottom" ? BOTTOM : TOP

  const allowedBarNames = ["default", "separated-islands"]

  let spacing =
    !allowedBarNames.includes(SETTINGS.barAppearence.layout) &&
    SETTINGS.barAppearence.compact
      ? 5
      : 0
  if (SETTINGS.barAppearence.layout === "transparent") spacing = 5
  if (SETTINGS.theme === "transparent-catppuccin") spacing = 5
  if (SETTINGS.barAppearence.layout === "separated-islands") spacing = 5

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

  return (
    <window
      visible
      name={WINDOWS_NAMESPACES.bar}
      namespace={WINDOWS_NAMESPACES.bar}
      class={`Bar test ${barCss}`}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={
        !SETTINGS.barAppearence.island
          ? verticalAnchor | LEFT | RIGHT
          : verticalAnchor
      }
      application={app}
    >
      <Container>
        <Layout monitor={gdkmonitor} />
      </Container>
    </window>
  )
}
