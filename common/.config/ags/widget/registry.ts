import Battery from "./widgets/Battery/Battery"
import {} from "ags"
import AudioButton from "./widgets/Audio/Audio"
import NetworkButton from "./widgets/Network/NetworkButton"
import Workspaces from "./widgets/Workspaces/workspaces"
import NowPlaying from "./widgets/Audio/Playing"
import CurrentApp from "./widgets/CurrentApp/CurrentApp"
import { Gdk } from "ags/gtk4"
import Clock from "./widgets/Clock"
import { AVAILABLE_WIDGETS } from "../config/types"
import TimerButton from "./widgets/Timer/TimerButton"
import DashboardButton from "./widgets/Dashboard/DashboardButton"
import { Tray } from "./widgets/Tray/Tray"

export type WidgetFunction = (props: { monitor: Gdk.Monitor }) => JSX.Element

export const WIDGETS: Record<AVAILABLE_WIDGETS, WidgetFunction> = {
  battery: Battery,
  audio: AudioButton,
  network: NetworkButton,
  "now-playing": NowPlaying,
  "current-app": CurrentApp,
  workspaces: Workspaces,
  clock: Clock,
  timer: TimerButton,
  dashboard: DashboardButton,
  tray: Tray,
}
