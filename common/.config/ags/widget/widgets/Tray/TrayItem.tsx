import { Gtk } from "ags/gtk4"
import AstalTray from "gi://AstalTray"

export function TrayItemButton({
  item,
  className,
}: {
  item: AstalTray.TrayItem
  className?: string
}) {
  const button = new Gtk.MenuButton({ has_frame: false })
  button.add_css_class("tray-item")
  if (className) button.add_css_class(className)

  const image = new Gtk.Image({ icon_size: Gtk.IconSize.NORMAL })
  button.child = image

  function update() {
    if (item.gicon) {
      image.gicon = item.gicon
    } else if (item.icon_name) {
      image.icon_name = item.icon_name
    }

    const tooltip = item.tooltip_text || item.title || ""
    if (tooltip) button.tooltip_text = tooltip

    if (item.menu_model) {
      button.menu_model = item.menu_model
      button.insert_action_group("dbusmenu", item.action_group)
    }
  }

  update()

  const changedHandler = item.connect("changed", update)
  button.connect("destroy", () => item.disconnect(changedHandler))

  return button as unknown as JSX.Element
}
