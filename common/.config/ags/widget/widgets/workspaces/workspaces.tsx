import AstalHyprland from "gi://AstalHyprland?version=0.1"
import { Gtk, Gdk } from "ags/gtk4"
import { createPoll } from "ags/time"
import { createBinding, createComputed, With } from "ags"
import WorkspaceButton from "./WorkspaceButton"
import { SETTINGS } from "../../../config/Settings"
import { WorkspaceRange } from "./WorkspacesSettingsType"

export default function Workspaces({ monitor }: { monitor: Gdk.Monitor }) {
  const monitorSettings: WorkspaceRange = SETTINGS.workspaces.monitors[
    monitor.get_model() ?? "NULL"
  ] ?? { from: 1, to: 20, minWorkspaces: 5 }

  console.log(monitorSettings.minWorkspaces)

  const hypr = AstalHyprland.get_default()
  const Five = Array(monitorSettings?.minWorkspaces ?? 5).fill(0)
  const hyprlandWorkspaces = createBinding(hypr, "workspaces")

  return (
    <box
      $type="start"
      class="workspaces"
      orientation={Gtk.Orientation.HORIZONTAL}
    >
      <With value={hyprlandWorkspaces}>
        {(workspaces) => {
          const sortedWorkspaces = workspaces.sort((a, b) => a.id - b.id)
          return (
            <box>
              {Five.map((_, index) => (
                <WorkspaceButton
                  id={monitorSettings?.from + index}
                  hyprInstance={hypr}
                />
              ))}
              {sortedWorkspaces.map((element: AstalHyprland.Workspace) =>
                element.id > Five.length &&
                monitorSettings.to >= element.id &&
                monitorSettings.from <= element.id ? (
                  <WorkspaceButton id={element.id} hyprInstance={hypr} />
                ) : (
                  <box />
                ),
              )}
            </box>
          )
        }}
      </With>
    </box>
  )
}
