import { Gtk } from "ags/gtk4"
import { createState, With } from "ags"
import SettingsSectionButton from "./SettingsSectionButton"
import { ShellSettings } from "../../../utils/SettingsManager"
import { execAsync } from "ags/process"
import BarAppearanceSection from "./sections/BarAppearanceSection"
import WorkspacesSection from "./sections/WorkspacesSection"
import NowPlayingSection from "./sections/NowPlayingSection"
import WidgetsSection from "./sections/WidgetsSection"
import WallpapersSection from "./sections/WallpapersSection"
import { placeWorkspaceInMonitor } from "../../../utils/workspaces"

const options = {
  bar: { label: "Bar Appearance", icon: "󰸌" },
  workspace: { label: "Workspaces", icon: "󱂬" },
  nowPlaying: { label: "Now Playing", icon: "󰝚" },
  widgets: { label: "Widgets", icon: "󱒊" },
  wallpapers: { label: "Wallpapers", icon: "󰸉" },
}

const SECTIONS: Record<string, () => JSX.Element> = {
  "Bar Appearance": () => <BarAppearanceSection />,
  Workspaces: () => <WorkspacesSection />,
  "Now Playing": () => <NowPlayingSection />,
  Widgets: () => <WidgetsSection />,
  Wallpapers: () => <WallpapersSection />,
}

export function SettingsWidget() {
  const [focusedWindow, setFocusedWindow] = createState(options.bar.label)
  return (
    <box>
      <box
        class="settings-window"
        orientation={Gtk.Orientation.VERTICAL}
        spacing={10}
      >
        <centerbox>
          <label $type="start" class="settings-window-title" label="Settings" />
          <box $type="end" halign={Gtk.Align.END}>
            <button
              class="settings-apply-button"
              onClicked={() => {
                ShellSettings.getInstance().save()
                placeWorkspaceInMonitor()
                execAsync(["bash", "./reload.sh"])
              }}
            >
              <label label="Apply" />
            </button>
          </box>
        </centerbox>
        <box vexpand>
          <box
            class="settings-window-buttons"
            orientation={Gtk.Orientation.VERTICAL}
          >
            <With value={focusedWindow}>
              {(active) => (
                <box orientation={Gtk.Orientation.VERTICAL}>
                  {Object.keys(options).map((key) => {
                    const opt = options[key as keyof typeof options]
                    return (
                      <SettingsSectionButton
                        active={active === opt.label}
                        label={opt.label}
                        icon={opt.icon}
                        onClick={() => setFocusedWindow(opt.label)}
                      />
                    )
                  })}
                </box>
              )}
            </With>
          </box>
          <With value={focusedWindow}>
            {(active) => (
              <scrolledwindow
                vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
                hscrollbarPolicy={Gtk.PolicyType.NEVER}
                propagateNaturalHeight={true}
                maxContentHeight={600}
              >
                <box
                  class="settings-window-content"
                  orientation={Gtk.Orientation.VERTICAL}
                >
                  {SECTIONS[active]?.()}
                </box>
              </scrolledwindow>
            )}
          </With>
        </box>
      </box>
    </box>
  )
}
