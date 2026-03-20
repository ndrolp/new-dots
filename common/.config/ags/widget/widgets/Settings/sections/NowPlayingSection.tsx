import { Gtk } from "ags/gtk4"
import { createComputed, createState } from "ags"
import { ShellSettings } from "../../../../utils/SettingsManager"

export default function NowPlayingSection() {
  const s = ShellSettings.getInstance()

  const [showControls, setShowControls] = createState(s.nowPlaying.showControls)

  return (
    <box orientation={Gtk.Orientation.VERTICAL} spacing={12} class="settings-section">
      <label
        class="settings-section-title"
        label="Now Playing"
        halign={Gtk.Align.START}
      />

      <box spacing={10} halign={Gtk.Align.START}>
        <button
          class={createComputed(() =>
            `settings-toggle${showControls() ? " active" : ""}`,
          )}
          onClicked={() => {
            const v = !showControls()
            s.nowPlaying.showControls = v
            s.save()
            setShowControls(v)
          }}
        >
          <label label={createComputed(() => (showControls() ? "On" : "Off"))} />
        </button>
        <label label="Show Controls" />
      </box>

      <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
        <label
          label="Preferred Clients"
          class="settings-row-label"
          halign={Gtk.Align.START}
        />
        <box spacing={6}>
          {s.nowPlaying.preferedClients.length === 0 ? (
            <label label="None" class="settings-muted" />
          ) : (
            s.nowPlaying.preferedClients.map((c) => (
              <label class="settings-chip" label={c} />
            ))
          )}
        </box>
      </box>

      <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
        <label
          label="Ignored Clients"
          class="settings-row-label"
          halign={Gtk.Align.START}
        />
        <box spacing={6}>
          {s.nowPlaying.ignoreClients.length === 0 ? (
            <label label="None" class="settings-muted" />
          ) : (
            s.nowPlaying.ignoreClients.map((c) => (
              <label class="settings-chip" label={c} />
            ))
          )}
        </box>
      </box>
    </box>
  )
}
