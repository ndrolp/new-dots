import CustomWindow from "../../common/Window"
import { WINDOWS_NAMESPACES } from "../../windows"
import { Gtk } from "ags/gtk4"
import { createState, With } from "ags"
import { SettingsWidget } from "./SettingsWidget"

export default function SettingsWindow() {
  return (
    <CustomWindow
      resizable={false}
      name={WINDOWS_NAMESPACES.settings}
      namespace={WINDOWS_NAMESPACES.settings}
      position={Gtk.Align.CENTER}
    >
      <SettingsWidget />
    </CustomWindow>
  )
}
