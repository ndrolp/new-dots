import { createPoll } from "ags/time"
import app from "ags/gtk4/app"
import { WALLPAPER_PICKER_NAMESPACE } from "./Wallpaper/WallpaperPicker"

export default function Clock() {
  // const date = createPoll("", 1000, `bash -c "date +%H:%M"`)
  const date = createPoll("", 1000, () => {
    return new Date().toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    })
  })

  return (
    <menubutton class="bar-icon clock">
      <box class="fg-blue">
        <label class="icon" label="󰥔" />
        <label label={date} />
      </box>
    </menubutton>
  )
}
