import Notifd from "gi://AstalNotifd"
import { Gdk, Gtk } from "ags/gtk4"
import Gio from "gi://Gio"
import Adw from "gi://Adw"
import { isPath, wrapWords } from "../../../../utils/stringFunctions"
import { interval, timeout } from "ags/time"
import { createState } from "gnim"

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
  const expire = notification.expire_timeout < 3000 ? 3000 : 3000
  const [timeNow, setTimeNow] = createState(0)
  const [revealed, setRevealed] = createState(false)

  console.log("Notification expire timeout:", expire)

  const timer = interval(100, () => {})

  const watch = timer.connect("now", (time) => {
    setRevealed(true)
    if (timeNow() >= expire) {
      timer.cancel()
      timer.disconnect(watch)

      onHide(notification)
    }
    setTimeNow((prev) => prev + 100)
    console.log("Timer tick:", timeNow())
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
        orientation={Gtk.Orientation.VERTICAL}
        halign={Gtk.Align.CENTER}
        css_classes={["notification-box"]}
      >
        <box
          orientation={Gtk.Orientation.VERTICAL}
          overflow={Gtk.Overflow.HIDDEN}
        >
          <Adw.Clamp maximum_size={200} orientation={Gtk.Orientation.VERTICAL}>
            <box class="" orientation={Gtk.Orientation.HORIZONTAL} spacing={0}>
              <box
                visible={isPath(notification.image)}
                class="image-container"
                halign={Gtk.Align.CENTER}
              >
                <box
                  class="image"
                  halign={Gtk.Align.CENTER}
                  valign={Gtk.Align.CENTER}
                >
                  <Adw.Clamp
                    valign={Gtk.Align.START}
                    maximumSize={80}
                    widthRequest={80}
                    heightRequest={80}
                  >
                    <Adw.Clamp
                      orientation={Gtk.Orientation.VERTICAL}
                      maximumSize={80}
                    >
                      <Gtk.Picture
                        class="picture"
                        contentFit={Gtk.ContentFit.COVER}
                        file={Gio.file_new_for_path(notification.image)}
                      />
                    </Adw.Clamp>
                  </Adw.Clamp>
                </box>
              </box>
              <box
                class="content"
                orientation={Gtk.Orientation.VERTICAL}
                spacing={5}
              >
                <centerbox
                  hexpand
                  class="header"
                  orientation={Gtk.Orientation.HORIZONTAL}
                >
                  <box $type="start" orientation={Gtk.Orientation.VERTICAL}>
                    <label
                      class="title"
                      halign={Gtk.Align.START}
                      label={notification.summary}
                    />
                    <label
                      class="app"
                      halign={Gtk.Align.START}
                      label={notification.appName}
                    />
                  </box>
                  <button
                    $type="end"
                    cursor={Gdk.Cursor.new_from_name("pointer", null)}
                    halign={Gtk.Align.END}
                    valign={Gtk.Align.START}
                    class="close"
                    label=""
                    onClicked={() => {
                      setRevealed(false)
                      timer.disconnect(watch)
                      timer.cancel()
                      if (onHide) onHide(notification)
                    }}
                  ></button>
                </centerbox>
                <box class="body">
                  <label
                    maxWidthChars={10}
                    label={wrapWords(notification.body, 30)}
                  />
                </box>
              </box>
            </box>
          </Adw.Clamp>
        </box>
      </box>
    </revealer>
  )
}
