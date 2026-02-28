import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import Workspaces from "./widgets/workspaces/workspaces"
import Clock from "./widgets/Clock"
import Battery from "./widgets/Battery/Battery"
import { SETTINGS } from "../config/Settings"
import AudioButton from "./widgets/Audio/Audio"
import { monitorFile, readFile } from "ags/file"
import { createBinding, createState, For, With } from "ags"
import { IShellSettings } from "../config/types"
import Gio from "gi://Gio?version=2.0"

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor
  const [currentSettings, updateCurrentSettings] = createState(
    JSON.parse(readFile("settings.json")) as IShellSettings,
  )

  const Container = ({
    children,
  }: {
    children: JSX.Element | Array<JSX.Element>
  }) => {
    if (SETTINGS.barAppearence.island) {
      return (
        <box hexpand cssName="centerbox" class="bar-content">
          {children}
        </box>
      )
    }
    return (
      <centerbox cssName="centerbox" class="bar-content">
        {children}
      </centerbox>
    )
  }

  return (
    <window
      visible
      name="bar"
      class={`Bar 
          ${SETTINGS.theme ?? "catppuccin"} 
          layout-${SETTINGS.barAppearence.layout ?? "default"} 
          rounding-${SETTINGS.barAppearence.rounding} 
          ${SETTINGS.barAppearence.compact ? "compact" : ""}`}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={!SETTINGS.barAppearence.island ? TOP | LEFT | RIGHT : TOP}
      application={app}
    >
      <Container>
        <box $type="start" marginEnd={5}>
          <button margin_end={5} class="bar-icon test">
            <box class="">
              <label label="" />
            </box>
          </button>
          <Workspaces monitor={gdkmonitor} />
        </box>
        <box hexpand halign={Gtk.Align.CENTER} $type="center">
          <Clock />
        </box>
        <box hexpand halign={Gtk.Align.END} $type="end" margin_start={5}>
          <AudioButton />
          <Battery />
        </box>
      </Container>
    </window>
  )
}
