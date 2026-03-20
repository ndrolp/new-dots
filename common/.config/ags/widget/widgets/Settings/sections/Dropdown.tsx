import { Gtk } from "ags/gtk4"
import { createComputed, createState } from "ags"

export default function Dropdown<T extends string>({
  items,
  selected,
  onSelect,
}: {
  items: T[]
  selected: () => T
  onSelect: (v: T) => void
}) {
  const [open, setOpen] = createState(false)

  return (
    <box orientation={Gtk.Orientation.VERTICAL} spacing={0} class="dropdown">
      <button
        class="dropdown-trigger"
        onClicked={() => setOpen((v) => !v)}
      >
        <box spacing={8} halign={Gtk.Align.FILL} hexpand>
          <label
            hexpand
            halign={Gtk.Align.START}
            label={createComputed(() => selected())}
            class="dropdown-value"
          />
          <label
            class="dropdown-arrow"
            label={createComputed(() => (open() ? "" : ""))}
          />
        </box>
      </button>
      <revealer
        transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
        transitionDuration={150}
        revealChild={createComputed(() => open())}
        onNotifyChildRevealed={(self) => {
          if (!self.childRevealed) self.get_root()?.queue_resize()
        }}
      >
        <box orientation={Gtk.Orientation.VERTICAL} class="dropdown-list" spacing={2}>
          {items.map((item) => (
            <button
              class={createComputed(() =>
                `dropdown-item${selected() === item ? " active" : ""}`,
              )}
              onClicked={() => {
                onSelect(item)
                setOpen(false)
              }}
            >
              <label label={item} halign={Gtk.Align.START} />
            </button>
          ))}
        </box>
      </revealer>
    </box>
  )
}
