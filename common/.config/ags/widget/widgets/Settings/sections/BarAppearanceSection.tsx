import { Gtk } from "ags/gtk4"
import { createComputed, createState } from "ags"
import { ShellSettings } from "../../../../utils/SettingsManager"
import { IBarAppearence, SHEL_THEME } from "../../../../config/types"
import Dropdown from "./Dropdown"

const THEMES: SHEL_THEME[] = [
  "catppuccin",
  "gruvbox-dark",
  "nord",
  "transparent-catppuccin",
]
const ROUNDINGS: IBarAppearence["rounding"][] = [
  "none",
  "sm",
  "md",
  "lg",
  "full",
]
const LAYOUTS: IBarAppearence["layout"][] = [
  "default",
  "transparent",
  "separated-islands",
]

export default function BarAppearanceSection() {
  const s = ShellSettings.getInstance()

  const [theme, setTheme] = createState<SHEL_THEME>(s.theme)
  const [island, setIsland] = createState(s.barAppearence.island)
  const [compact, setCompact] = createState(s.barAppearence.compact)
  const [float, setFloat] = createState(s.barAppearence.float)
  const [showBorder, setShowBorder] = createState(s.barAppearence.showBorder)
  const [rounding, setRounding] = createState(s.barAppearence.rounding)
  const [layout, setLayout] = createState(s.barAppearence.layout)

  return (
    <box
      hexpand
      orientation={Gtk.Orientation.VERTICAL}
      spacing={12}
      class="settings-section"
    >
      <label
        class="settings-section-title"
        label="Bar Appearance"
        halign={Gtk.Align.START}
      />

      <box hexpand orientation={Gtk.Orientation.VERTICAL} spacing={4}>
        <label
          label="Theme"
          class="settings-row-label"
          halign={Gtk.Align.START}
        />
        <Dropdown
          items={THEMES}
          selected={theme}
          onSelect={(t) => {
            s.setColorscheme(t)
            setTheme(t)
          }}
        />
      </box>

      <box hexpand orientation={Gtk.Orientation.VERTICAL} spacing={4}>
        <label
          label="Layout"
          class="settings-row-label"
          halign={Gtk.Align.START}
        />
        <Dropdown
          items={LAYOUTS}
          selected={layout}
          onSelect={(l) => {
            s.barAppearence.layout = l
            s.save()
            setLayout(l)
          }}
        />
      </box>

      <box hexpand orientation={Gtk.Orientation.VERTICAL} spacing={4}>
        <label
          label="Rounding"
          class="settings-row-label"
          halign={Gtk.Align.START}
        />
        <Dropdown
          items={ROUNDINGS}
          selected={rounding}
          onSelect={(r) => {
            s.barAppearence.rounding = r
            s.save()
            setRounding(r)
          }}
        />
      </box>

      <box hexpand orientation={Gtk.Orientation.VERTICAL} spacing={6}>
        <label
          label="Options"
          class="settings-row-label"
          halign={Gtk.Align.START}
        />
        {(
          [
            ["Island", island, setIsland, "island"],
            ["Compact", compact, setCompact, "compact"],
            ["Float", float, setFloat, "float"],
            ["Show Border", showBorder, setShowBorder, "showBorder"],
          ] as [
            string,
            () => boolean,
            (v: boolean) => void,
            keyof IBarAppearence,
          ][]
        ).map(([label, get, set, key]) => (
          <box spacing={10} halign={Gtk.Align.START}>
            <button
              class={createComputed(
                () => `settings-toggle${get() ? " active" : ""}`,
              )}
              onClicked={() => {
                const v = !get()
                ;(s.barAppearence[key] as boolean) = v
                s.save()
                set(v)
              }}
            >
              <label label={createComputed(() => (get() ? "On" : "Off"))} />
            </button>
            <label label={label} />
          </box>
        ))}
      </box>
    </box>
  )
}
