import { Gtk } from "ags/gtk4"
import { createState, With } from "ags"
import { ShellSettings } from "../../../../utils/SettingsManager"
import { AVAILABLE_WIDGETS, IWidgetLayout } from "../../../../config/types"
import Dropdown from "./Dropdown"
import { chunk } from "./utils"

const ALL_WIDGETS: AVAILABLE_WIDGETS[] = [
  "battery",
  "audio",
  "network",
  "now-playing",
  "current-app",
  "workspaces",
  "clock",
  "timer",
  "dashboard",
]

const VARIANTS = ["default", "flush", "island"] as const
type Variant = (typeof VARIANTS)[number]

function PositionEditor({
  label,
  groups,
  setGroups,
}: {
  label: string
  groups: () => AVAILABLE_WIDGETS[][]
  setGroups: (g: AVAILABLE_WIDGETS[][]) => void
}) {
  const usedWidgets = () => groups().flat()
  const available = () => ALL_WIDGETS.filter((w) => !usedWidgets().includes(w))

  return (
    <box
      orientation={Gtk.Orientation.VERTICAL}
      spacing={6}
      class="position-editor"
    >
      <box spacing={6} halign={Gtk.Align.FILL} hexpand>
        <label
          label={label}
          class="settings-row-label"
          hexpand
          halign={Gtk.Align.START}
        />
        <button
          class="settings-chip add"
          onClicked={() => setGroups([...groups(), []])}
        >
          <label label=" Group" />
        </button>
      </box>

      <With value={groups}>
        {(gs) => (
          <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
            {gs.length === 0 ? (
              <label
                label="No groups"
                class="settings-muted"
                halign={Gtk.Align.START}
              />
            ) : (
              gs.map((group, gi) => (
                <box
                  orientation={Gtk.Orientation.VERTICAL}
                  spacing={4}
                  class="widget-group"
                >
                  <box spacing={4}>
                    <label
                      label={`Group ${gi + 1}`}
                      class="settings-muted"
                      hexpand
                      halign={Gtk.Align.START}
                    />
                    <button
                      class="widget-row-btn remove"
                      onClicked={() =>
                        setGroups(groups().filter((_, i) => i !== gi))
                      }
                    >
                      <label label="" />
                    </button>
                  </box>

                  {group.length === 0 ? (
                    <label
                      label="Empty"
                      class="settings-muted"
                      halign={Gtk.Align.START}
                    />
                  ) : (
                    <box orientation={Gtk.Orientation.VERTICAL} spacing={1}>
                      {chunk(group, 4).map((row, rowIdx) => (
                        <box spacing={1}>
                          {row.map((w, colIdx) => {
                            const wi = rowIdx * 4 + colIdx
                            return (
                              <box spacing={0} class="widget-chip-row">
                                <button
                                  class="widget-row-btn"
                                  sensitive={wi > 0}
                                  onClicked={() => {
                                    const g = [...groups()]
                                    const grp = [...g[gi]]
                                    ;[grp[wi - 1], grp[wi]] = [
                                      grp[wi],
                                      grp[wi - 1],
                                    ]
                                    g[gi] = grp
                                    setGroups(g)
                                  }}
                                >
                                  <label label="" />
                                </button>
                                <label label={w} class="widget-row-label" />
                                <button
                                  class="widget-row-btn"
                                  sensitive={wi < group.length - 1}
                                  onClicked={() => {
                                    const g = [...groups()]
                                    const grp = [...g[gi]]
                                    ;[grp[wi], grp[wi + 1]] = [
                                      grp[wi + 1],
                                      grp[wi],
                                    ]
                                    g[gi] = grp
                                    setGroups(g)
                                  }}
                                >
                                  <label label="" />
                                </button>
                                <button
                                  class="widget-row-btn remove"
                                  onClicked={() => {
                                    const g = [...groups()]
                                    g[gi] = g[gi].filter((_, j) => j !== wi)
                                    setGroups(g)
                                  }}
                                >
                                  <label label="" />
                                </button>
                              </box>
                            )
                          })}
                        </box>
                      ))}
                    </box>
                  )}

                  <box
                    orientation={Gtk.Orientation.VERTICAL}
                    spacing={4}
                    marginTop={4}
                  >
                    {chunk(available(), 6).map((row) => (
                      <box spacing={4}>
                        {row.map((w) => (
                          <button
                            class="settings-chip add"
                            onClicked={() => {
                              const g = [...groups()]
                              g[gi] = [...g[gi], w]
                              setGroups(g)
                            }}
                          >
                            <label label={` ${w}`} />
                          </button>
                        ))}
                      </box>
                    ))}
                  </box>
                </box>
              ))
            )}
          </box>
        )}
      </With>
    </box>
  )
}

function LayoutEditor({ variant }: { variant: Variant }) {
  const s = ShellSettings.getInstance()
  const layout: IWidgetLayout = s.widgets[variant] ?? s.widgets.default

  const [left, setLeft] = createState<AVAILABLE_WIDGETS[][]>(layout.left)
  const [center, setCenter] = createState<AVAILABLE_WIDGETS[][]>(layout.center)
  const [right, setRight] = createState<AVAILABLE_WIDGETS[][]>(layout.right)

  const sync =
    (
      pos: "left" | "center" | "right",
      setter: (g: AVAILABLE_WIDGETS[][]) => void,
    ) =>
    (g: AVAILABLE_WIDGETS[][]) => {
      setter(g)
      s.widgets[variant] = {
        ...(s.widgets[variant] ?? s.widgets.default),
        [pos]: g,
      }
    }

  return (
    <box orientation={Gtk.Orientation.VERTICAL} spacing={12} hexpand>
      <PositionEditor
        label="Left"
        groups={left}
        setGroups={sync("left", setLeft)}
      />
      <box class="position-separator" />
      <PositionEditor
        label="Center"
        groups={center}
        setGroups={sync("center", setCenter)}
      />
      <box class="position-separator" />
      <PositionEditor
        label="Right"
        groups={right}
        setGroups={sync("right", setRight)}
      />
    </box>
  )
}

export default function WidgetsSection() {
  const [variant, setVariant] = createState<Variant>("default")

  return (
    <box
      orientation={Gtk.Orientation.VERTICAL}
      spacing={12}
      class="settings-section"
    >
      <label
        class="settings-section-title"
        label="Widgets"
        halign={Gtk.Align.START}
      />

      <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
        <label
          label="Layout Variant"
          class="settings-row-label"
          halign={Gtk.Align.START}
        />
        <Dropdown
          items={[...VARIANTS]}
          selected={variant}
          onSelect={setVariant}
        />
      </box>

      <With value={variant}>{(v) => <LayoutEditor variant={v} />}</With>
    </box>
  )
}
