import { Gtk } from "ags/gtk4"
import Notifd from "gi://AstalNotifd"
import { createBinding, With } from "ags"

function NotificationCard({
  notification,
  onDismiss,
}: {
  notification: Notifd.Notification
  onDismiss: () => void
}) {
  return (
    <box
      class="nc-card"
      orientation={Gtk.Orientation.VERTICAL}
      spacing={4}
      hexpand
    >
      <box hexpand spacing={0}>
        <label
          class="nc-card-app"
          label={notification.appName}
          halign={Gtk.Align.START}
          hexpand
          ellipsize={3}
        />
        <button
          class="nc-card-close"
          onClicked={onDismiss}
          valign={Gtk.Align.CENTER}
        >
          <label label="" />
        </button>
      </box>
      <label
        class="nc-card-title"
        label={notification.summary}
        halign={Gtk.Align.START}
        hexpand
        ellipsize={3}
        maxWidthChars={30}
      />
      {notification.body.length > 0 && (
        <label
          class="nc-card-body"
          label={notification.body}
          halign={Gtk.Align.START}
          hexpand
          wrap
          maxWidthChars={30}
          lines={2}
          ellipsize={3}
        />
      )}
    </box>
  )
}

export function NotificationsPanel() {
  const notifd = Notifd.get_default()
  const notifications = createBinding(notifd, "notifications")

  return (
    <box
      class="nc-notifs"
      orientation={Gtk.Orientation.VERTICAL}
      spacing={0}
      hexpand
    >
      <With value={notifications}>
        {(notifs) => {
          if (notifs.length === 0)
            return (
              <box
                class="nc-empty"
                orientation={Gtk.Orientation.VERTICAL}
                spacing={8}
                hexpand
                vexpand
                halign={Gtk.Align.CENTER}
                valign={Gtk.Align.CENTER}
              >
                <label class="nc-empty-icon" label="󰂚" />
                <label class="nc-empty-text" label="No notifications" />
              </box>
            )

          return (
            <box orientation={Gtk.Orientation.VERTICAL} spacing={0} hexpand>
              <box class="nc-notifs-header" hexpand>
                <label
                  class="nc-notifs-label"
                  label="Notifications"
                  hexpand
                  halign={Gtk.Align.START}
                />
                <button
                  class="nc-clear-btn"
                  onClicked={() =>
                    notifd.get_notifications().forEach((n) => n.dismiss())
                  }
                  valign={Gtk.Align.CENTER}
                  tooltipText="Clear all"
                >
                  <label label="Clear" />
                </button>
              </box>
              <box orientation={Gtk.Orientation.VERTICAL} spacing={6} hexpand>
                {notifs.map((notification) => (
                  <NotificationCard
                    notification={notification}
                    onDismiss={() => notification.dismiss()}
                  />
                ))}
              </box>
            </box>
          )
        }}
      </With>
    </box>
  )
}
