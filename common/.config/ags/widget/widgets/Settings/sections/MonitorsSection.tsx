import { Gtk } from "ags/gtk4"
import { ShellSettings } from "../../../../utils/SettingsManager"

export default function MonitorsSection() {
  const s = ShellSettings.getInstance()
  const monitors = Object.entries(s.workspaces.monitors)

  return (
    <box orientation={Gtk.Orientation.VERTICAL} spacing={12} class="settings-section">
      <label
        class="settings-section-title"
        label="Monitors"
        halign={Gtk.Align.START}
      />

      {monitors.length === 0 ? (
        <label
          label="No monitors configured"
          class="settings-row-label"
          halign={Gtk.Align.START}
        />
      ) : (
        <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
          {monitors.map(([name, range]) => (
            <box
              orientation={Gtk.Orientation.VERTICAL}
              spacing={4}
              class="settings-monitor-card"
            >
              <label
                label={name}
                class="settings-row-label"
                halign={Gtk.Align.START}
              />
              <box spacing={12}>
                <box spacing={4}>
                  <label label="From" class="settings-muted" />
                  <label label={range.from.toString()} class="settings-chip" />
                </box>
                <box spacing={4}>
                  <label label="To" class="settings-muted" />
                  <label label={range.to.toString()} class="settings-chip" />
                </box>
                <box spacing={4}>
                  <label label="Min" class="settings-muted" />
                  <label
                    label={range.minWorkspaces.toString()}
                    class="settings-chip"
                  />
                </box>
              </box>
            </box>
          ))}
        </box>
      )}
    </box>
  )
}
