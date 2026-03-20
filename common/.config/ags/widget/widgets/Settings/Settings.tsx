import CustomWindow from "../../common/Window"
import { WINDOWS_NAMESPACES } from "../../windows"
import { Gtk } from "ags/gtk4"
import SettingsSectionButton from "./SettingsSectionButton"
import { createState, With } from "ags"

const options = {
  bar: { label: "Bar Appearance", icon: "" },
  workspace: { label: "Workspaces", icon: "" },
  monitors: { label: "Monitors", icon: "󰍹" },
  barSettings: { label: "Bar Settings", icon: "" },
}

export default function SettingsWindow() {
  let [focusedWindow, setFocusedWindow] = createState(options.bar.label)
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
        <With value={focusedWindow}>
          {(active) => {
            return (
              <box>
                <box
                  class="settings-window-buttons"
                  orientation={Gtk.Orientation.VERTICAL}
                >
                  {Object.keys(options).map((key) => {
                    const option = options[key as keyof typeof options]
                    return (
                      <SettingsSectionButton
                        active={active === option.label}
                        label={option.label}
                        icon={option.icon}
                        onClick={() => {
                          setFocusedWindow(option.label)
                        }}
                      />
                    )
                  })}
                </box>
                <box class="settings-window-content"></box>
              </box>
            )
          }}
        </With>
      </box>
    </CustomWindow>
  )
}
