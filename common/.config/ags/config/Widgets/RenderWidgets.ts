import Battery from "../../widget/widgets/Battery/Battery"
import {} from "ags"
import AudioButton from "../../widget/widgets/Audio/Audio"
import NetworkButton from "../../widget/widgets/Network/NetworkButton"
import Workspaces from "../../widget/widgets/workspaces/workspaces"
import NowPlaying from "../../widget/widgets/Audio/Playing"
import CurrentApp from "../../widget/widgets/CurrentApp/CurrentApp"
import { Gdk } from "ags/gtk4"
import Clock from "../../widget/widgets/Clock"
import { AVAILABLE_WIDGETS } from "../types"

export type WidgetFunction = (props: { monitor: Gdk.Monitor }) => JSX.Element

export const WIDGETS: Record<AVAILABLE_WIDGETS, WidgetFunction> = {
  battery: Battery,
  audio: AudioButton,
  network: NetworkButton,
  "now-playing": NowPlaying,
  "current-app": CurrentApp,
  workspaces: Workspaces,
  clock: Clock,
}
