import app from "ags/gtk4/app"
import { Gtk } from "ags/gtk4"
import style from "./style.scss"
import Bar from "./widget/Bar"
import { monitorFile } from "ags/file"
import Gio from "gi://Gio?version=2.0"
import { execAsync } from "ags/process"
import Dashboard from "./widget/widgets/Dashboard/Dashboard"
import NetworkDashboard from "./widget/widgets/Network/NetworkDashboard"
import { ShellSettings } from "./utils/SettingsManager"
import {
  DEFAULT_BAR_APPEARENCE,
  SHELL_THEMES_BINDER,
} from "./utils/settings/DefaultBarAppearances"
import ActiveNotifications from "./widget/widgets/Notifications/ActiveNotifications"
import WallpaperPicker from "./widget/widgets/Wallpaper/WallpaperPicker"
import SettingsWindow from "./widget/widgets/Settings/Settings"
import ClockPanel from "./widget/widgets/ClockPanel"

const runApp = () =>
  app.start({
    requestHandler(argv: string[], response: (response: string) => void) {
      const settings = ShellSettings.getInstance()
      const [cmd, arg, ...rest] = argv
      if (cmd == "appearence") {
        settings.setAppearence(arg as DEFAULT_BAR_APPEARENCE)
        execAsync(["bash", "-c", "~/.config/ags/reload.sh"])
        return response(arg)
      }
      if (cmd == "theme") {
        settings.setColorscheme(SHELL_THEMES_BINDER[arg])
        execAsync(["bash", "-c", "~/.config/ags/reload.sh"])
        return response("THEME APPLIED")
      }
      if (cmd == "toggle") {
        app.toggle_window(arg)
      }
      response("unknown command")
    },
    css: style,
    main() {
      app.get_monitors().map((monitor) => {
        Bar(monitor)
      })
      NetworkDashboard(Gtk.Align.END)
      Dashboard()
      ActiveNotifications()
      ClockPanel()
      WallpaperPicker()
      SettingsWindow()
    },
  })

monitorFile("settings.json", (file, event) => {
  // updateCurrentSettings(JSON.parse(file))
  if (event === Gio.FileMonitorEvent.CHANGES_DONE_HINT) {
    execAsync(["bash", "-c", "~/.config/ags/reload.sh"])
  }
})

runApp()
