import { Gtk } from "ags/gtk4"
import { createState } from "ags"
import { ShellSettings } from "../../../../utils/SettingsManager"
import { WorkspacesConfig } from "../../../../config/types"
import Dropdown from "./Dropdown"

const DISPLAY_TYPES: WorkspacesConfig["displayType"][] = [
  "dots",
  "numbers",
  "icons",
  "icons-filled",
]

export default function WorkspacesSection() {
  const s = ShellSettings.getInstance()

  const [displayType, setDisplayType] = createState(s.workspaces.displayType)

  return (
    <box orientation={Gtk.Orientation.VERTICAL} spacing={12} class="settings-section">
      <label
        class="settings-section-title"
        label="Workspaces"
        halign={Gtk.Align.START}
      />

      <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
        <label
          label="Display Type"
          class="settings-row-label"
          halign={Gtk.Align.START}
        />
        <Dropdown
          items={DISPLAY_TYPES}
          selected={displayType}
          onSelect={(t) => {
            s.workspaces.displayType = t
            s.save()
            setDisplayType(t)
          }}
        />
      </box>
    </box>
  )
}
