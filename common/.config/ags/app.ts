import app from "ags/gtk4/app"
import { Gtk } from "ags/gtk4"
import style from "./style.scss"
import Bar from "./widget/Bar"
import themes from "./styles/themes.scss"
import BatteryDashboard from "./widget/widgets/Battery/BatteryDashboard"
import { monitorFile } from "ags/file"
import Gio from "gi://Gio?version=2.0"
import { execAsync } from "ags/process"
import Dashboard from "./widget/widgets/Dashboard/Dashboard"
import NetworkDashboard from "./widget/widgets/Network/NetworkDashboard"
import { ShellSettings } from "./utils/SettingsManager"
import {
  DEFAULT_BAR_APPEARENCE,
  SHELL_THEMES_BINDER,
} from "./utils/settings/DefaultBarAppearences"

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
      response("unknown command")
    },
    css: style,
    main() {
      app.get_monitors().map((monitor) => {
        Bar(monitor)
        BatteryDashboard()
        NetworkDashboard(Gtk.Align.END)
        Dashboard()
      })
    },
  })

monitorFile("settings.json", (file, event) => {
  // updateCurrentSettings(JSON.parse(file))
  if (event === Gio.FileMonitorEvent.CHANGES_DONE_HINT) {
    execAsync(["bash", "-c", "~/.config/ags/reload.sh"])
  }
})

runApp()
