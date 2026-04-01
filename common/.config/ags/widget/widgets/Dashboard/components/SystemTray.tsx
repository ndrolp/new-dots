import { Gtk } from "ags/gtk4"
import { createBinding, With } from "ags"
import AstalTray from "gi://AstalTray"

function TrayItemButton({ item }: { item: AstalTray.TrayItem }) {
  const btn = new Gtk.MenuButton({ has_frame: false })
  btn.add_css_class("tray-item")

  const img = new Gtk.Image({ icon_size: Gtk.IconSize.NORMAL })
  btn.child = img

  function update() {
    if (item.gicon) {
      img.gicon = item.gicon
    } else if (item.icon_name) {
      img.icon_name = item.icon_name
    }

    const tooltip = item.tooltip_text || item.title || ""
    if (tooltip) btn.tooltip_text = tooltip

    if (item.menu_model) {
      btn.menu_model = item.menu_model
      btn.insert_action_group("dbusmenu", item.action_group)
    }
  }

  update()

  const changedHandler = item.connect("changed", update)
  btn.connect("destroy", () => item.disconnect(changedHandler))

  return btn as unknown as JSX.Element
}

export function SystemTray() {
  const tray = AstalTray.get_default()
  const items = createBinding(tray, "items")

  return (
    <box class="system-tray" spacing={2} halign={Gtk.Align.CENTER} hexpand>
      <With value={items}>
        {(trayItems) =>
          trayItems.length > 0 ? (
            <box spacing={2} halign={Gtk.Align.CENTER} hexpand>
              {trayItems.map((item) => (
                <TrayItemButton item={item} />
              ))}
            </box>
          ) : (
            <label
              label="No tray items"
              class="empty-label"
              hexpand
              halign={Gtk.Align.CENTER}
            />
          )
        }
      </With>
    </box>
  )
}
