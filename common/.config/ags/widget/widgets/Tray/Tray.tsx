import { createBinding, With } from "ags"
import AstalTray from "gi://AstalTray"
import { TrayItemButton } from "./TrayItem"

export function Tray() {
  const tray = AstalTray.get_default()
  const items = createBinding(tray, "items")

  return (
    <box class="tray bar-icon" spacing={2}>
      <With value={items}>
        {(trayItems) =>
          trayItems.length > 0 ? (
            <box spacing={2}>
              {trayItems.map((item) => (
                <TrayItemButton item={item} className="bar-icon" />
              ))}
            </box>
          ) : null
        }
      </With>
    </box>
  )
}
