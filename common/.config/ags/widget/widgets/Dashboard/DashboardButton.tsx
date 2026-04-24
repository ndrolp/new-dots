import app from "ags/gtk4/app"
import { Gdk } from "ags/gtk4"
import { WINDOWS_NAMESPACES } from "../../windows"

export default function DashboardButton(_: { monitor: Gdk.Monitor }) {
  return (
    <button
      class="bar-icon dashboard-button"
      onClicked={() => app.toggle_window(WINDOWS_NAMESPACES.dashboard)}
    >
      <label label="" />
    </button>
  )
}
