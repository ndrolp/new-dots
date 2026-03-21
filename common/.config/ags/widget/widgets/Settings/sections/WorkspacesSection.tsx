import { Gtk, Gdk } from "ags/gtk4"
import { createState } from "ags"
import { ShellSettings } from "../../../../utils/SettingsManager"
import { WorkspaceRange, WorkspacesConfig } from "../../../../config/types"
import Dropdown from "./Dropdown"

const DISPLAY_TYPES: WorkspacesConfig["displayType"][] = [
  "dots",
  "numbers",
  "icons",
  "icons-filled",
]

function getConnectedMonitorNames(): string[] {
  const display = Gdk.Display.get_default()
  if (!display) return []
  const list = display.get_monitors()
  const names: string[] = []
  for (let i = 0; i < list.get_n_items(); i++) {
    const monitor = list.get_item(i) as Gdk.Monitor
    const model = monitor.get_model()
    if (model) names.push(model)
  }
  return names
}

function MonitorCard({ name }: { name: string }) {
  const s = ShellSettings.getInstance()
  const existing: WorkspaceRange = s.workspaces.monitors[name] ?? {
    from: 1,
    to: 10,
    minWorkspaces: 5,
  }

  if (!s.workspaces.monitors[name]) {
    s.workspaces.monitors[name] = { ...existing }
  }

  const updateField = (key: keyof WorkspaceRange, raw: string) => {
    const num = parseInt(raw, 10)
    if (!isNaN(num)) {
      s.workspaces.monitors[name][key] = num
    }
  }

  const fields: [string, keyof WorkspaceRange, number][] = [
    ["From", "from", existing.from],
    ["To", "to", existing.to],
    ["Min Workspaces", "minWorkspaces", existing.minWorkspaces],
  ]

  return (
    <box
      orientation={Gtk.Orientation.VERTICAL}
      spacing={8}
      class="settings-monitor-card"
    >
      <label label={name} class="settings-row-label" halign={Gtk.Align.START} />
      <box spacing={16}>
        {fields.map(([label, key, initial]) => (
          <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
            <label
              label={label}
              class="settings-muted"
              halign={Gtk.Align.START}
            />
            <entry
              text={initial.toString()}
              widthChars={5}
              class="settings-monitor-entry"
              $={(self) => {
                self.connect("changed", () =>
                  updateField(key, self.get_text()),
                )
              }}
            />
          </box>
        ))}
      </box>
    </box>
  )
}

export default function WorkspacesSection() {
  const s = ShellSettings.getInstance()
  const connectedMonitors = getConnectedMonitorNames()

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

      <label
        label="Monitors"
        class="settings-row-label"
        halign={Gtk.Align.START}
      />
      {connectedMonitors.length === 0 ? (
        <label
          label="No monitors detected"
          class="settings-muted"
          halign={Gtk.Align.START}
        />
      ) : (
        <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
          {connectedMonitors.map((name) => (
            <MonitorCard name={name} />
          ))}
        </box>
      )}
    </box>
  )
}
