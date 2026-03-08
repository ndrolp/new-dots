import AstalHyprland from "gi://AstalHyprland?version=0.1"
import { createBinding, createComputed, With } from "ags"
import { ShellSettings } from "../../../utils/SettingsManager"

export default function WorkspaceButton({
  hyprInstance,
  id,
  showId = false,
  margin_left = 0,
  margin_right = 0,
}: {
  hyprInstance: AstalHyprland.Hyprland
  id: number
  showId?: boolean
  margin_left?: number
  margin_right?: number
}) {
  const SETTINGS = ShellSettings.getInstance()
  const instance = hyprInstance.workspaces.find((element) => element.id === id)
  const focusedWorkspace = createBinding(hyprInstance, "focusedWorkspace")
  focusedWorkspace().clients

  const workspaceIcon = createComputed(() => {
    if (SETTINGS.workspaces.displayType === "numbers") {
      return id.toString()
    }
    return id == focusedWorkspace().id ? "" : ""
  })

  const workspaceClass = createComputed(() => {
    let classes = "workspace-button"
    if (id === focusedWorkspace().id) {
      classes += " focused"
    }
    if (SETTINGS.workspaces.displayType === "dots") {
      classes += " dot"
    } else {
      classes += " numbers"
    }
    return classes
  })

  return (
    <box marginStart={margin_left} marginEnd={margin_right}>
      <box
        $type="start"
        hexpand={false}
        vexpand={false}
        cssClasses={[
          "workspace-button-container",
          SETTINGS.workspaces.displayType,
        ]}
        class={`workspace-button-container ${(instance?.clients?.length ?? 0 > 0) ? "test" : ""}`}
      >
        <button
          onClicked={() => hyprInstance.dispatch("workspace", id.toString())}
          class={workspaceClass}
        >
          <label label={workspaceIcon} />
        </button>
      </box>
    </box>
  )
}
