import { Gtk } from "ags/gtk4"
import CustomWindow from "../../common/Window"

const WALLPAPER_PICKER_NAMESPACE = "wallpaper_picker"

export default function WallpaperPicker() {
  return (
    <CustomWindow
      visible={false}
      css=""
      position={Gtk.Align.CENTER}
      name={WALLPAPER_PICKER_NAMESPACE}
      namespace={WALLPAPER_PICKER_NAMESPACE}
    >
      <box>
        <label label="Wallpaper Picker" />
      </box>
    </CustomWindow>
  )
}
