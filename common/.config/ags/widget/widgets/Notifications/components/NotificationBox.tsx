import Notifd from "gi://AstalNotifd"
import { createState, onCleanup } from "ags"
import { Gdk, Gtk } from "ags/gtk4"
import Gio from "gi://Gio"
import { isPath } from "../../../../utils/stringFunctions"
import { interval } from "ags/time"

const MIN_NOTIFICATION_TIMEOUT = 3000
const DEFAULT_NOTIFICATION_TIMEOUT = 5000

function getNotificationTimeout(notification: Notifd.Notification) {
  if (notification.expire_timeout === 0) return 0
  if (notification.expire_timeout < 0) return DEFAULT_NOTIFICATION_TIMEOUT

  return Math.max(notification.expire_timeout, MIN_NOTIFICATION_TIMEOUT)
}

export default function NotificationBox({
  notification,
  showActions = true,
  last = false,
  onHide = () => {},
}: {
  notification: Notifd.Notification
  showActions?: boolean
  onHide?: (notification: Notifd.Notification) => void
  last?: boolean
}) {
  const expire = getNotificationTimeout(notification)
  const [revealed, setRevealed] = createState(true)
  const body = notification.body ?? ""
  let hidden = false

  const timer =
    expire > 0
      ? interval(100, () => {
          if (hidden) return
          expireRemaining -= 100
          if (expireRemaining > 0) return

          hidden = true
          timer?.cancel()
          setRevealed(false)
          onHide(notification)
        })
      : null
  let expireRemaining = expire

  const hasBody = body.trim().length > 0
  const imagePath = notification.image
  const appIcon = notification.appIcon

  function hideNotification() {
    if (hidden) return

    hidden = true
    setRevealed(false)
    timer?.cancel()
    if (onHide) onHide(notification)
  }

  onCleanup(() => {
    timer?.cancel()
  })

  return (
    <revealer
      transition_type={
        last
          ? Gtk.RevealerTransitionType.SLIDE_DOWN
          : Gtk.RevealerTransitionType.SLIDE_DOWN
      }
      revealChild={revealed}
      transition_duration={300}
    >
      <box
        class={`notification-box ${last ? "notification-box-last" : ""}`}
        spacing={10}
        halign={Gtk.Align.CENTER}
      >
        {isPath(imagePath) ? (
          <box
            class="image-container notification-image"
            widthRequest={80}
            heightRequest={80}
            overflow={Gtk.Overflow.HIDDEN}
          >
            <Gtk.Picture
              class="picture"
              canShrink
              contentFit={Gtk.ContentFit.COVER}
              file={Gio.file_new_for_path(imagePath)}
              widthRequest={80}
              heightRequest={80}
            />
          </box>
        ) : (
          appIcon && (
            <box class="image-container">
              <image class="icon" iconName={appIcon} pixelSize={36} />
            </box>
          )
        )}
        <box class="content" spacing={10}>
          <label
            class="app"
            label={notification.appName || "Notification"}
            valign={Gtk.Align.CENTER}
          />
          <box
            class="text"
            orientation={Gtk.Orientation.VERTICAL}
            spacing={2}
            hexpand
          >
            <label
              class="title"
              halign={Gtk.Align.START}
              label={notification.summary}
              ellipsize={3}
              maxWidthChars={32}
            />
            {hasBody && (
              <label
                class="body"
                halign={Gtk.Align.START}
                label={body}
                ellipsize={3}
                lines={1}
                maxWidthChars={42}
              />
            )}
          </box>
        </box>
        {showActions && (
          <button
            cursor={Gdk.Cursor.new_from_name("pointer", null)}
            halign={Gtk.Align.END}
            valign={Gtk.Align.CENTER}
            class="close"
            onClicked={hideNotification}
          >
            <label label="󰅖" />
          </button>
        )}
      </box>
    </revealer>
  )
}
