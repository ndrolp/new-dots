import CustomWindow from "../../common/Window"
import { WINDOWS_NAMESPACES } from "../../windows"
import { Gtk } from "ags/gtk4"
import { createComputed, createState, With } from "ags"
import SettingsSectionButton from "./SettingsSectionButton"
import { ShellSettings } from "../../../utils/SettingsManager"
import { execAsync } from "ags/process"
import BarAppearanceSection from "./sections/BarAppearanceSection"
import WorkspacesSection from "./sections/WorkspacesSection"
import MonitorsSection from "./sections/MonitorsSection"
import NowPlayingSection from "./sections/NowPlayingSection"

const options = {
  bar: { label: "Bar Appearance", icon: "󰸌" },
  workspace: { label: "Workspaces", icon: "󱂬" },
  monitors: { label: "Monitors", icon: "󰍹" },
  nowPlaying: { label: "Now Playing", icon: "󰝚" },
}

const onCollapsed = (self: Gtk.Revealer) => {
  if (!self.childRevealed) self.get_parent()?.queue_resize()
}

export default function SettingsWindow() {
  const [focusedWindow, setFocusedWindow] = createState(options.bar.label)

  return (
    <CustomWindow
      visible={true}
      resizable={false}
      name={WINDOWS_NAMESPACES.settings}
      namespace={WINDOWS_NAMESPACES.settings}
      position={Gtk.Align.CENTER}
    >
      <box>
        <box
          class="settings-window"
          orientation={Gtk.Orientation.VERTICAL}
          spacing={10}
        >
          <centerbox>
            <label
              $type="start"
              class="settings-window-title"
              label="Settings"
            />
            <box $type="end" halign={Gtk.Align.END}>
              <button
                class="settings-apply-button"
                onClicked={() => {
                  ShellSettings.getInstance().save()
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
            <box
              class="settings-window-content"
              orientation={Gtk.Orientation.VERTICAL}
            >
              <revealer
                transitionType={Gtk.RevealerTransitionType.SWING_DOWN}
                transitionDuration={200}
                revealChild={createComputed(
                  () => focusedWindow() === options.bar.label,
                )}
                onNotifyChildRevealed={onCollapsed}
              >
                <box>
                  <BarAppearanceSection />
                </box>
              </revealer>
              <revealer
                transitionType={Gtk.RevealerTransitionType.SWING_DOWN}
                transitionDuration={200}
                revealChild={createComputed(
                  () => focusedWindow() === options.workspace.label,
                )}
                onNotifyChildRevealed={onCollapsed}
              >
                <box>
                  <WorkspacesSection />
                </box>
              </revealer>
              <revealer
                transitionType={Gtk.RevealerTransitionType.SWING_DOWN}
                transitionDuration={200}
                revealChild={createComputed(
                  () => focusedWindow() === options.monitors.label,
                )}
                onNotifyChildRevealed={onCollapsed}
              >
                <box>
                  <MonitorsSection />
                </box>
              </revealer>
              <revealer
                transitionType={Gtk.RevealerTransitionType.SWING_DOWN}
                transitionDuration={200}
                revealChild={createComputed(
                  () => focusedWindow() === options.nowPlaying.label,
                )}
                onNotifyChildRevealed={onCollapsed}
              >
                <box>
                  <NowPlayingSection />
                </box>
              </revealer>
            </box>
          </box>
        </box>
      </box>
    </CustomWindow>
  )
}
