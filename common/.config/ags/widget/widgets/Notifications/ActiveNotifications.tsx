import app from "ags/gtk4/app"
import Notifd from "gi://AstalNotifd"
import { createComputed, createState, onCleanup, With } from "ags"
import NotificationBox from "./components/NotificationBox"
import { Gtk, Astal } from "ags/gtk4"
import { getWindowSettingsCssClasses } from "../../../utils/mainBar"
import Logger from "../../../utils/logger"
import { WINDOWS_NAMESPACES } from "../../windows"

export default function ActiveNotifications() {
  const notifd = Notifd.get_default()
  const { log } = Logger.getInstance()

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

  onCleanup(() => {
    log("Cleaning up ActiveNotifications component, disconnecting signals")
    notifd.disconnect(notifiedHandler)
    notifd.disconnect(resolvedHandler)
  })

  return (
    <window
      visible={createComputed(() => activeNotifications().length > 0)}
      name={WINDOWS_NAMESPACES.notifications}
      namespace={WINDOWS_NAMESPACES.notifications}
      anchor={Astal.WindowAnchor.TOP}
      application={app}
      exclusivity={Astal.Exclusivity.IGNORE}
      class={"notification-overlay  window " + getWindowSettingsCssClasses()}
    >
      <box
        class="notification-overlay__content"
        orientation={Gtk.Orientation.VERTICAL}
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.START}
      >
        <With value={activeNotifications}>
          {(notifications) => {
            return (
              <box
                class="notification-pane"
                orientation={Gtk.Orientation.VERTICAL}
                spacing={0}
                halign={Gtk.Align.CENTER}
              >
                {notifications.map((notification, index) => {
                  return (
                    <NotificationBox
                      key={notification.id}
                      notification={notification}
                      onHide={handleHideNotification}
                      last={index === notifications.length - 1}
                    />
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
