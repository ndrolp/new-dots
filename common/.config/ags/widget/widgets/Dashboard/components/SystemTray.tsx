import { Gtk } from "ags/gtk4"
import { createBinding, With } from "ags"
import AstalTray from "gi://AstalTray"
import { TrayItemButton } from "../../Tray/TrayItem"

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
