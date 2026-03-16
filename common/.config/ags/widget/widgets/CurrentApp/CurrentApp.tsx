import { Gtk, Gdk } from "ags/gtk4"
import AstalHyprland from "gi://AstalHyprland"
import { createBinding, createComputed, With } from "ags"
import { getActiveClientIcon } from "../../../utils/activeClient"
import { truncateString } from "../../../utils/stringFunctions"

export default function CurrentApp({ monitor }: { monitor: Gdk.Monitor }) {
  const hypr = AstalHyprland.get_default()
  const activeClient = createBinding(hypr, "focusedClient")
  const title = createBinding(hypr, "focusedClient", "title")
  const hyprWorkspace = createBinding(hypr, "focusedWorkspace")

  const monitorIsVisible = createComputed(() => {
    if (activeClient() == null || activeClient.name === "") return false
    return hyprWorkspace().monitor.model == monitor.model
  })

  const noClient = createComputed(() => {
    if (
      (activeClient() == null || activeClient.name === "") &&
      hyprWorkspace().monitor.model == monitor.model
    )
      return true

    return false
  })

  const displayData = createComputed(() => {
    return {
      client: activeClient(),
      class: activeClient().initialClass,
      title: title(),
    }
  })

  return (
    <box>
      <revealer
        reveal_child={monitorIsVisible}
        transition_duration={200}
        transitionType={Gtk.RevealerTransitionType.SLIDE_LEFT}
      >
        <box class="bar-icon current-app" spacing={5} visible={true}>
          <With value={displayData}>
            {(data) => {
              const icon = getActiveClientIcon(data.class, data.title)
              return (
                <box>
                  <label label={getActiveClientIcon(data.class, data.title)} />
                  <label label={truncateString(data.title ?? "Desktop", 50)} />
                </box>
              )
            }}
          </With>
        </box>
      </revealer>
      <revealer
        reveal_child={noClient}
        transition_duration={200}
        transitionType={Gtk.RevealerTransitionType.SLIDE_LEFT}
      >
        <box class="bar-icon current-app" spacing={5} visible={true}>
          <label label="" />
          <label label="Desktop" />
        </box>
      </revealer>
    </box>
  )
}
