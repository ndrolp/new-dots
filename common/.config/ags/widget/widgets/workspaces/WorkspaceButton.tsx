import AstalHyprland from "gi://AstalHyprland?version=0.1"
import { createBinding, With } from "ags"

export default function WorkspaceButton({
  hyprInstance,
  id,
  showId = false,
}: {
  hyprInstance: AstalHyprland.Hyprland
  id: number
  showId?: boolean
}) {
  const instance = hyprInstance.workspaces.find((element) => element.id === id)
  const focusedWorkspace = createBinding(hyprInstance, "focusedWorkspace")

  return (
    <box>
      <With value={focusedWorkspace}>
        {(focusedElement) => {
          const getWorkspaceIcon = (): string => {
            const isFocused = focusedElement.id === id

            // return id.toString()
            return isFocused ? "" : ""
          }
          return (
            <box
              $type="start"
              hexpand={false}
              vexpand={false}
              class={`workspace-button-container`}
            >
              <button
                onClicked={() =>
                  hyprInstance.dispatch("workspace", id.toString())
                }
                class={`workspace-button ${focusedElement.id === id ? "focused" : ""}`}
              >
                <label label={getWorkspaceIcon()} />
              </button>
            </box>
          )
        }}
      </With>
    </box>
  )
}
