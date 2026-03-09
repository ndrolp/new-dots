import AstalHyprland from "gi://AstalHyprland?version=0.1"
import { Gtk, Gdk } from "ags/gtk4"
import { createBinding, createComputed, With } from "ags"
import WorkspaceButton from "./WorkspaceButton"
import { SETTINGS } from "../../../config/Settings"
import { WorkspaceRange } from "./WorkspacesSettingsType"

export default function Workspaces({ monitor }: { monitor: Gdk.Monitor }) {
  const monitorSettings: WorkspaceRange = SETTINGS.workspaces.monitors[
    monitor.get_model() ?? "NULL"
  ] ?? { from: 1, to: 20, minWorkspaces: 5 }

  console.log(monitorSettings.minWorkspaces)
  const monitorsToDISPLAY = monitorSettings.to - monitorSettings.from + 1

  const hypr = AstalHyprland.get_default()
  const allWorkspaces = Array(monitorsToDISPLAY).fill(0)
  const hyprlandWorkspaces = createBinding(hypr, "workspaces")

  return (
    <box
      $type="start"
      class="bar-icon workspaces "
      orientation={Gtk.Orientation.HORIZONTAL}
    >
      <box spacing={0}>
        {allWorkspaces.map((_, index) => (
          <revealer
            transitionType={Gtk.RevealerTransitionType.SWING_RIGHT}
            transitionDuration={200}
            revealChild={createComputed(() => {
              const sortedWorkspaces = hyprlandWorkspaces().sort(
                (a, b) => a.id - b.id,
              )
              const workspaceId = monitorSettings.from + index
              const workspaceExists = sortedWorkspaces.some(
                (workspace) => workspace.id === workspaceId,
              )
              return (
                workspaceExists || workspaceId <= monitorSettings.minWorkspaces
              )
            })}
          >
            <box>
              <WorkspaceButton
                id={monitorSettings?.from + index}
                hyprInstance={hypr}
                margin_left={index === 0 ? 0 : 2}
                margin_right={index === allWorkspaces.length - 1 ? 0 : 2}
              />
            </box>
          </revealer>
        ))}
      </box>
    </box>
  )
}
