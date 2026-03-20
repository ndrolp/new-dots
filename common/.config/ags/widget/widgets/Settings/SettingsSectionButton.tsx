import { Gtk } from "ags/gtk4"

export default function SettingsSectionButton({
  label,
  icon,
  active = false,
  onClick,
}: {
  label: string
  icon: string
  active?: boolean
  onClick: () => void
}) {
  return (
    <box vexpand={false} hexpand>
      <button
        vexpand={false}
        hexpand
        class={
          active ? "settings-section-button active" : "settings-section-button"
        }
        onClicked={onClick}
      >
        <box spacing={15} halign={Gtk.Align.START} valign={Gtk.Align.CENTER}>
          <label class="icon" label={icon} />
          <label label={label} />
        </box>
      </button>
    </box>
  )
}
