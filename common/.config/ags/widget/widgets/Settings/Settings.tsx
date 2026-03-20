import CustomWindow from "../../common/Window"
import { WINDOWS_NAMESPACES } from "../../windows"
import { Gtk } from "ags/gtk4"
import SettingsSectionButton from "./SettingsSectionButton"

export default function SettingsWindow() {
  return (
    <CustomWindow
      visible={true}
      name={WINDOWS_NAMESPACES.settings}
      namespace={WINDOWS_NAMESPACES.settings}
      position={Gtk.Align.CENTER}
    >
      <box
        class="settings-window"
        orientation={Gtk.Orientation.VERTICAL}
        spacing={10}
      >
        <label class="settings-window-title" label="Settings" />
        <box>
          <box
            class="settings-window-buttons"
            orientation={Gtk.Orientation.VERTICAL}
          >
            <SettingsSectionButton
              active
              label="Bar Appearance"
              icon=""
              onClick={() => {}}
            />
            <SettingsSectionButton
              label="Workspaces"
              icon=""
              onClick={() => {}}
            />
            <SettingsSectionButton
              label="Monitors"
              icon="󰍹"
              onClick={() => {}}
            />
            <SettingsSectionButton
              label="Bar Settings"
              icon=""
              onClick={() => {}}
            />
          </box>
          <box class="settings-window-content"></box>
        </box>
      </box>
    </CustomWindow>
  )
}
