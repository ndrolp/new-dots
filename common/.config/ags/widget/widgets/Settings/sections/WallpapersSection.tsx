import { Gtk } from "ags/gtk4"
import { WallpaperPickerContent } from "../../Wallpaper/WallpaperPicker"

export default function WallpapersSection() {
  return (
    <box
      orientation={Gtk.Orientation.VERTICAL}
      spacing={12}
      class="settings-section"
    >
      <label
        class="settings-section-title"
        label="Wallpapers"
        halign={Gtk.Align.START}
      />
      <WallpaperPickerContent />
    </box>
  )
}
