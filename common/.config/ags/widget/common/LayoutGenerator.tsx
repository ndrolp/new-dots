import { Gdk } from "ags/gtk4"
import { IWidgetLayout } from "../../config/types"
import { WIDGETS } from "../../config/Widgets/RenderWidgets"

export default function LayoutGenerator({
  layout,
  monitor,
}: {
  layout: IWidgetLayout
  monitor: Gdk.Monitor
}) {
  console.log({ layout })
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
          <box $type={type} spacing={5}>
            {layout[position as keyof IWidgetLayout].map((widgetRow) => {
              return (
                <box class="bar-section">
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
