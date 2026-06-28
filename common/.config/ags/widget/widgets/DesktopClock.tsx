import { Astal } from "ags/gtk4"
import app from "ags/gtk4/app"

export const DesktopClock = ({}) => {
  const { TOP, RIGHT, LEFT, BOTTOM } = Astal.WindowAnchor
  return (
    <window
      visible={false}
      application={app}
      layer={Astal.Layer.BACKGROUND}
      exclusivity={Astal.Exclusivity.IGNORE}
      anchor={TOP}
    >
      <label label="10:45" />
    </window>
  )
}
