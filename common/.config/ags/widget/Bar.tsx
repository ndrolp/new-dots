import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import Workspaces from "./widgets/workspaces/workspaces"
import Clock from "./widgets/Clock"
import Battery from "./widgets/Battery/Battery"
import { SETTINGS } from "../config/Settings"
import AudioButton from "./widgets/Audio/Audio"

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible
      name="bar"
      class={`Bar catppuccin layout-${SETTINGS.layout}`}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <centerbox cssName="centerbox" class="bar-content">
        <box $type="start" halign={Gtk.Align.START} marginEnd={5}>
          <button margin_end={5} class="bar-icon test">
            <box class="">
              <label label="" />
            </box>
          </button>
          <Workspaces monitor={gdkmonitor} />
        </box>
        <box $type="center">
          <Clock />
        </box>
        <box $type="end" halign={Gtk.Align.END} margin_start={5}>
          <AudioButton />
          <Battery />
        </box>
      </centerbox>
    </window>
  )
}
