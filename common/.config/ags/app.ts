import app from "ags/gtk4/app"
import style from "./style.scss"
import Bar from "./widget/Bar"
import themes from "./styles/themes.scss"
import BatteryDashboard from "./widget/widgets/Battery/BatteryDashboard"
import { monitorFile } from "ags/file"
import Gio from "gi://Gio?version=2.0"
import { execAsync } from "ags/process"
import Dashboard from "./widget/widgets/Dashboard/Dashboard"

const runApp = () =>
  app.start({
    css: style,
    main() {
      app.get_monitors().map((monitor) => {
        console.log(monitor.model)
        Bar(monitor)
        BatteryDashboard()
        Dashboard()
      })
    },
  })

monitorFile("settings.json", (file, event) => {
  // updateCurrentSettings(JSON.parse(file))
  if (event === Gio.FileMonitorEvent.CHANGES_DONE_HINT) {
    console.log("RESTARTING AGS")
    execAsync(["bash", "-c", "~/.config/ags/reload.sh"])
  }
})

runApp()
