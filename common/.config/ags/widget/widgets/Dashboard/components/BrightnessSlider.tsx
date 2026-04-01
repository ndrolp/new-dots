import { Gtk } from "ags/gtk4"
import { createState, createComputed, With } from "ags"
import { execAsync } from "ags/process"

export function BrightnessSlider() {
  const [brightness, setBrightness] = createState(0.5)
  const [available, setAvailable] = createState(true)

  execAsync("brightnessctl g")
    .then((curr) =>
      execAsync("brightnessctl m").then((max) => {
        const v = parseInt(curr) / parseInt(max)
        setBrightness(isNaN(v) ? 0.5 : v)
      }),
    )
    .catch(() => setAvailable(false))

  const pctLabel = createComputed(() => `${Math.round(brightness() * 100)}%`)

  return (
    <With value={available}>
      {(ok) =>
        ok ? (
          <box class="brightness-row" spacing={10} hexpand>
            <label class="brightness-icon" label="󰃞" />
            <slider
              class="brightness-slider"
              hexpand
              draw_value={false}
              min={0.02}
              max={1}
              value={brightness}
              onValueChanged={(self) => {
                const v = self.value
                if (Math.abs(v - brightness.peek()) > 0.005) {
                  setBrightness(v)
                  execAsync(["brightnessctl", "s", `${Math.round(v * 100)}%`])
                }
              }}
            />
            <label class="brightness-pct" label={pctLabel} />
          </box>
        ) : (
          <></>
        )
      }
    </With>
  )
}
