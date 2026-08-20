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
    const client = activeClient()
    const workspace = hyprWorkspace()
    if (client == null) return false
    return workspace?.monitor?.model == monitor.model
  })

  const noClient = createComputed(() => {
    const client = activeClient()
    const workspace = hyprWorkspace()
    return (
      client == null &&
      workspace?.monitor?.model == monitor.model
    )
  })

  const displayData = createComputed(() => {
    const client = activeClient()
    return {
      class: client?.initialClass ?? "",
      title: title() ?? client?.title ?? "",
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
              return data?.class || data?.title ? (
                <box>
                  <label label={getActiveClientIcon(data.class, data.title)} />
                  <label label={truncateString(data.title ?? "Desktop", 50)} />
                </box>
              ) : (
                <box visible={false} />
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
