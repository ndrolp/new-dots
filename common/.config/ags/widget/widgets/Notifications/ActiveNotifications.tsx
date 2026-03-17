import app from "ags/gtk4/app"
import Notifd from "gi://AstalNotifd"
import {
  createBinding,
  createComputed,
  createState,
  For,
  onCleanup,
  With,
} from "ags"
import NotificationBox from "./components/NotificationBox"
import { Gtk, Astal } from "ags/gtk4"
import { getWindowSettingsCssClasses } from "../../../utils/mainBar"
import { ShellSettings } from "../../../utils/SettingsManager"
import Logger from "../../../utils/logger"
import { WINDOWS_NAMESPACES } from "../../windows"

export default function ActiveNotifications() {
  const SETTINGS = ShellSettings.getInstance()
  const notifd = Notifd.get_default()
  const { log } = Logger.getInstance()
  let contentbox: Gtk.Box

  const [activeNotifications, setActiveNotifications] = createState(
    [] as Notifd.Notification[],
  )

  const notifiedHandler = notifd.connect("notified", (_, id, replaced) => {
    const notification = notifd.get_notification(id)

    log("New notification:", {
      id,
      replaced,
      notification: notification?.summary,
    })

    if (replaced && notification) {
      log("Notification replaced:", {
        id,
        notification: notification.summary,
      })
      setActiveNotifications((actual) => {
        log("Updating notification in state:", {
          id,
          notification: notification.summary,
        })
        return actual.map((n) => (n.id === id ? notification : n))
      })
    } else if (notification) {
      log("Adding new notification to state:", {
        id,
        notification: notification.summary,
      })
      setActiveNotifications((ns) => [notification, ...ns])
    }
  })

  const resolvedHandler = notifd.connect("resolved", (_, id) => {
    log("Notification resolved:", { id })
    setActiveNotifications((ns) => ns.filter((n) => n.id !== id))
  })

  function handleHideNotification(notification: Notifd.Notification) {
    log("Hiding notification:", {
      id: notification.id,
      transient: notification.transient,
    })
    if (notification.transient) return notification.dismiss()

    log("Manually removing notification from state:", {
      id: notification.id,
    })
    setActiveNotifications((notifications) =>
      notifications.filter((notif) => notif.id !== notification.id),
    )
  }

  console.log(getWindowSettingsCssClasses())

  onCleanup(() => {
    log("Cleaning up ActiveNotifications component, disconnecting signals")
    notifd.disconnect(notifiedHandler)
    notifd.disconnect(resolvedHandler)
  })

  return (
    <window
      visible={createComputed(() => activeNotifications().length > 0)}
      name={WINDOWS_NAMESPACES.notifications}
      vexpand={false}
      anchor={Astal.WindowAnchor.TOP}
      application={app}
      valign={Gtk.Align.END}
      exclusivity={Astal.Exclusivity.NORMAL}
      class={"notification-overlay  window " + getWindowSettingsCssClasses()}
    >
      <box valign={Gtk.Align.START} class="" hexpand>
        <With value={activeNotifications}>
          {(notifications) => {
            return (
              <box orientation={Gtk.Orientation.VERTICAL} spacing={5}>
                {notifications.map((notification, index) => {
                  return (
                    <box class="notification-box" valign={Gtk.Align.END}>
                      <NotificationBox
                        notification={notification}
                        onHide={handleHideNotification}
                        last={index === notifications.length - 1}
                      />
                    </box>
                  )
                })}
              </box>
            )
          }}
        </With>
      </box>
    </window>
  )
}
