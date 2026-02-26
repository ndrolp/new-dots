import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { createPoll } from "ags/time"
import AstralHyprland from "gi://AstalHyprland"
import Workspaces from "./widgets/workspaces/workspaces"

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const time = createPoll("", 1000, "date")
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor
  const hypr = AstralHyprland.get_default()
  const WORKSPACES_1 = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

  const wps = hypr.get_workspaces()
  wps.forEach((element) => {
    console.log(element.name)
  })
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
          <Workspaces />
        </box>
        <box $type="center" />
        <box $type="end" />
      </centerbox>
    </window>
  )
}
