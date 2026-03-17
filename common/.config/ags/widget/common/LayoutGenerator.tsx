import { Gdk } from "ags/gtk4"
import { IWidgetLayout } from "../../config/types"
import { WIDGETS } from "../registry"
import { ShellSettings } from "../../utils/SettingsManager"

export default function LayoutGenerator({
  layout,
  monitor,
}: {
  layout: IWidgetLayout
  monitor: Gdk.Monitor
}) {
  const settings = ShellSettings.getInstance()
  return (
    <>
      {Object.keys(layout).map((position) => {
        const type =
          position === "center"
            ? "center"
            : position === "left"
              ? "start"
              : "end"
        return (
          <box
            $type={type}
            spacing={
              settings.barAppearence.layout === "separated-islands" ? 5 : 0
            }
          >
            {layout[position as keyof IWidgetLayout].map((widgetRow) => {
              return (
                <box class="bar-section" spacing={0}>
                  {widgetRow.map((widget) => {
                    const Widget = WIDGETS[widget as keyof typeof WIDGETS]({
                      monitor,
                    })
                    return <box>{Widget}</box>
                  })}
                </box>
              )
            })}
          </box>
        )
      })}
    </>
  )
}
