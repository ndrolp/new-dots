import app from "ags/gtk4/app"
import style from "./style.scss"
import Bar from "./widget/Bar"
import themes from "./styles/themes.scss"
import BatteryDashboard from "./widget/widgets/Battery/BatteryDashboard"

app.start({
  css: style,
  main() {
    app.get_monitors().map((monitor) => {
      Bar(monitor)
      BatteryDashboard()
    })
  },
})
