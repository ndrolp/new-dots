import { Gdk, Gtk } from "ags/gtk4"
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
  const SETTINGS = ShellSettings.getInstance()

  const allowedBarNames = ["default", "separated-islands"]

  let spacing =
    !allowedBarNames.includes(SETTINGS.barAppearence.layout) &&
    SETTINGS.barAppearence.compact
      ? 5
      : 0
  if (SETTINGS.barAppearence.layout === "transparent") spacing = 5
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
              SETTINGS.barAppearence.layout === "separated-islands" ? 10 : 5
            }
          >
            {layout[position as keyof IWidgetLayout].map((widgetRow) => {
              return (
                <box
                  class={"bar-section"}
                  orientation={Gtk.Orientation.HORIZONTAL}
                  spacing={spacing}
                >
                  {widgetRow.map((widget, index) => {
                    const length = widgetRow.length
                    const notWorkspace = widget !== "workspaces"
                    const Widget = WIDGETS[widget as keyof typeof WIDGETS]({
                      monitor,
                    })
                    return (
                      <box
                        class={
                          index === 0 && length > 1
                            ? "first"
                            : index === length - 1 && length > 1
                              ? "last"
                              : "sole"
                        }
                      >
                        {Widget}
                      </box>
                    )
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
