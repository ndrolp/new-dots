import AstalHyprland from "gi://AstalHyprland"
import { createBinding, createComputed, With } from "ags"
import { ShellSettings } from "../../../utils/SettingsManager"
import { Gdk } from "ags/gtk4"
import Logger from "../../../utils/logger"
import { execAsync } from "ags/process"

export default function WorkspaceButton({
  hyprInstance,
  id,
  showId = false,
  margin_left = 0,
  margin_right = 0,
  index = null,
}: {
  hyprInstance: AstalHyprland.Hyprland
  id: number
  showId?: boolean
  margin_left?: number
  margin_right?: number
  index?: number | null
}) {
  const log = Logger.getInstance()
  const SETTINGS = ShellSettings.getInstance()
  const focusedWorkspace = createBinding(hyprInstance, "focusedWorkspace")
  const allWorkspaces = createBinding(hyprInstance, "workspaces")

  const workspaceIcon = createComputed(() => {
    if (SETTINGS.workspaces.displayType === "numbers") {
      return id.toString()
    }
    if (
      SETTINGS.workspaces.displayType === "icons" ||
      SETTINGS.workspaces.displayType === "icons-filled"
    ) {
      return SETTINGS.workspaces.icons[id.toString()] ?? "󰣆"
    }
    return id === focusedWorkspace()?.id ? "" : ""
  })

  const workspaceClass = createComputed(() => {
    let classes = "workspace-button"

    const focused = focusedWorkspace()
    const focusedId = focused?.id
    const workspaces = [...allWorkspaces()]
      .filter((workspace) => workspace.id >= 0)
    const currentFound = workspaces.find((workspace) => {
      return workspace.id === id
    })

    log.separator()
    log.log("Computing classes for workspace", id)
    log.log("Focused workspace:", focusedId)
    log.log("Current workspace:", id)
    log.log("Is focused?", id === focusedId)
    log.log("Is occupied?", currentFound ? "Yes" : "No")

    if (id === focusedId) {
      classes += " focused"
    } else if (currentFound?.clients?.length ?? 0 > 0) {
      classes += " occupied"
    }

    switch (SETTINGS.workspaces.displayType) {
      case "dots":
        classes += " dots"
        break
      case "numbers":
        classes += " numbers"
        break
      case "icons":
        classes += " icons"
        break
      case "icons-filled":
        classes += " icons-filled"
        break
    }

    log.separator()
    return classes
  })

  return (
    <box marginStart={margin_left} marginEnd={margin_right}>
      <box
        cursor={Gdk.Cursor.new_from_name("pointer", null)}
        $type="start"
        hexpand={false}
        vexpand={false}
        cssClasses={[
          "workspace-button-container",
          SETTINGS.workspaces.displayType,
        ]}
      >
        <button
          onClicked={() => {
            execAsync([
              "hyprctl",
              "dispatch",
              `hl.dsp.focus({ workspace = '${id}' })`,
            ]).catch((error) =>
              log.error(`Failed to switch to workspace ${id}:`, error),
            )
          }}
          class={workspaceClass}
        >
          <label label={workspaceIcon} />
        </button>
      </box>
    </box>
  )
}
