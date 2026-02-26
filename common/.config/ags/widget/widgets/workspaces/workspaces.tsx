import AstalHyprland from "gi://AstalHyprland?version=0.1"
import { Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import { createBinding, createComputed, With } from "ags"
import WorkspaceButton from "./WorkspaceButton"

export default function Workspaces() {
  const labels = ["label1", "label2", "label3"]
  const hypr = AstalHyprland.get_default()
  const Five = Array(4).fill(0)
  const wp = hypr.get_focused_workspace()
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
                <WorkspaceButton id={index + 1} hyprInstance={hypr} />
              ))}
              {sortedWorkspaces.map(
                (element: AstalHyprland.Workspace, index) =>
                  element.id > Five.length ? (
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
