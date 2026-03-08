import { Gtk, Gdk } from "ags/gtk4"
import AstalHyprland from "gi://AstalHyprland"
import { createBinding, createComputed, With } from "ags"
import { getActiveClientIcon } from "../../../utils/activeClient"
import { truncateString } from "../../../utils/stringFunctions"

export default function CurrentApp({ monitor }: { monitor: Gdk.Monitor }) {
  const hypr = AstalHyprland.get_default()
  const activeClient = createBinding(hypr, "focusedClient")
  const title = createBinding(hypr, "focusedClient", "title")
  const className = createBinding(hypr, "focusedClient", "initialClass")

  const monitorIsVisible = createComputed(() => {
    if (activeClient() == null || activeClient.name === "") return false
    return activeClient().monitor.model == monitor.model
  })

  const displayData = createComputed(() => {
    return {
      client: activeClient(),
      class: activeClient().initialClass,
      title: title(),
    }
  })

  return (
    <box class="bar-icon" spacing={5} visible={monitorIsVisible}>
      <With value={displayData}>
        {(data) => {
          const icon = getActiveClientIcon(data.class, data.title)
          return (
            <box>
              <label label={getActiveClientIcon(data.class, data.title)} />
              <label label={truncateString(data.title, 50)} />
            </box>
          )
        }}
      </With>
    </box>
  )
}
