import { Gtk, Gdk } from "ags/gtk4"
import AstalHyprland from "gi://AstalHyprland"
import { createBinding, createComputed, With } from "ags"
import {
  ACTIVE_CLIENT_ICONS,
  getActiveClientIcon,
} from "../../../utils/activeClient"
import { truncateString } from "../../../utils/stringFunctions"

export default function CurrentApp({ monitor }: { monitor: Gdk.Monitor }) {
  const hypr = AstalHyprland.get_default()
  const activeClient = createBinding(hypr, "focusedClient")
  const title = createBinding(hypr, "focusedClient", "title")
  const className = createBinding(hypr, "focusedClient", "initialClass")

  const monitorIsVisible = createComputed(() => {
    if (activeClient() == null) return false
    return activeClient().monitor.model == monitor.model
  })
  const icon = createComputed(() => {
    return ACTIVE_CLIENT_ICONS[activeClient().initialClass]
  })

  const displayData = createComputed(() => {
    return {
      client: activeClient(),
      class: activeClient().initialClass,
      title: title(),
    }
  })

  return (
    <revealer
      transitionType={Gtk.RevealerTransitionType.SLIDE_LEFT}
      revealChild={monitorIsVisible}
    >
      <box class="bar-icon" spacing={5} visible={monitorIsVisible}>
        <With value={displayData}>
          {(data) => {
            const icon = getActiveClientIcon(data.class, data.title)
            return (
              <box>
                <label label={icon} />
                <label label={truncateString(data.title, 30)} />
              </box>
            )
          }}
        </With>
      </box>
    </revealer>
  )
}
