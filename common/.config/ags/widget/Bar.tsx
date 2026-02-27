import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import Workspaces from "./widgets/workspaces/workspaces"
import Clock from "./widgets/Clock"
import Battery from "./widgets/Battery/Battery"

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible
      name="bar"
      class="Bar catppuccin"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <centerbox cssName="centerbox" class="asd">
        <box $type="start">
          <Workspaces monitor={gdkmonitor} />
        </box>
        <box $type="center">
          <Clock />
        </box>
        <box $type="end">
          <Battery />
        </box>
      </centerbox>
    </window>
  )
}
