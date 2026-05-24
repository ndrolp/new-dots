import { Gtk } from "ags/gtk4"
import Notifd from "gi://AstalNotifd"
import { createBinding, createComputed, createState, With } from "ags"

function compactText(text: string) {
  return text.replace(/\s+/g, " ").trim()
}

interface NotificationGroupData {
  appName: string
  notifications: Notifd.Notification[]
}

function groupNotifications(
  notifications: Notifd.Notification[],
): NotificationGroupData[] {
  const groups = new Map<string, NotificationGroupData>()
  const order: string[] = []

  notifications.forEach((notification) => {
    const appName = compactText(notification.appName) || "Notification"
    const key = appName.toLowerCase()

    if (!groups.has(key)) {
      groups.set(key, { appName, notifications: [] })
      order.push(key)
    }

    groups.get(key)!.notifications.push(notification)
  })

  return order.map((key) => groups.get(key)!)
}

function NotificationCard({
  notification,
  onDismiss,
}: {
  notification: Notifd.Notification
  onDismiss: () => void
}) {
  const appName = compactText(notification.appName) || "Notification"
  const summary = compactText(notification.summary) || "Untitled notification"
  const body = compactText(notification.body)

  return (
    <box
      class="nc-card"
      orientation={Gtk.Orientation.VERTICAL}
      spacing={6}
      hexpand
      tooltipText={body.length > 0 ? `${summary}\n${body}` : summary}
    >
      <box class="nc-card-top" hexpand spacing={6}>
        <box class="nc-card-app-wrap" spacing={5} hexpand>
          <label class="nc-card-app-icon" label="󰂚" />
          <label
            class="nc-card-app"
            label={appName}
            halign={Gtk.Align.START}
            hexpand
            ellipsize={3}
          />
        </box>
        <button
          class="nc-card-close"
          onClicked={onDismiss}
          valign={Gtk.Align.CENTER}
          tooltipText="Dismiss notification"
        >
          <label label="󰅖" />
        </button>
      </box>
      <box class="nc-card-title-row" spacing={6}>
        <label class="nc-card-title-icon" label="󰍩" valign={Gtk.Align.START} />
        <label
          class="nc-card-title"
          label={summary}
          halign={Gtk.Align.START}
          hexpand
          ellipsize={3}
          maxWidthChars={28}
        />
      </box>
      {body.length > 0 && (
        <label
          class="nc-card-body"
          label={body}
          halign={Gtk.Align.START}
          hexpand
          wrap
          lines={2}
          ellipsize={3}
          maxWidthChars={34}
        />
      )}
    </box>
  )
}

function NotificationGroup({ group }: { group: NotificationGroupData }) {
  const [expanded, setExpanded] = createState(false)
  const hasMultiple = group.notifications.length > 1

  if (!hasMultiple) {
    const [notification] = group.notifications

    return (
      <NotificationCard
        notification={notification}
        onDismiss={() => notification.dismiss()}
      />
    )
  }

  const latest = group.notifications[0]
  const latestSummary = compactText(latest.summary) || "Untitled notification"
  const chevron = createComputed(() => (expanded() ? "󰅀" : "󰅂"))

  return (
    <box class="nc-group" orientation={Gtk.Orientation.VERTICAL} spacing={6}>
      <box class="nc-group-header" spacing={6} hexpand>
        <button
          class="nc-group-toggle"
          hexpand
          onClicked={() => setExpanded((value) => !value)}
          tooltipText={`${group.notifications.length} notifications from ${group.appName}`}
        >
          <box class="nc-group-toggle-inner" spacing={8} hexpand>
            <label
              class="nc-group-chevron"
              label={chevron}
              valign={Gtk.Align.CENTER}
            />
            <box
              class="nc-group-meta"
              orientation={Gtk.Orientation.VERTICAL}
              spacing={2}
              hexpand
            >
              <box class="nc-group-topline" spacing={6} hexpand>
                <label
                  class="nc-group-app"
                  label={group.appName}
                  halign={Gtk.Align.START}
                  hexpand
                  ellipsize={3}
                />
                <label
                  class="nc-group-count"
                  label={`${group.notifications.length}`}
                  halign={Gtk.Align.END}
                />
              </box>
              <label
                class="nc-group-summary"
                label={latestSummary}
                halign={Gtk.Align.START}
                hexpand
                ellipsize={3}
                maxWidthChars={28}
              />
            </box>
          </box>
        </button>
        <button
          class="nc-group-dismiss"
          onClicked={() =>
            group.notifications.forEach((notification) => notification.dismiss())
          }
          tooltipText={`Dismiss ${group.notifications.length} notifications`}
        >
          <label label="󰎟" />
        </button>
      </box>

      <revealer
        class="nc-group-revealer"
        transition_type={Gtk.RevealerTransitionType.SLIDE_DOWN}
        transition_duration={180}
        revealChild={expanded}
      >
        <box class="nc-group-list" orientation={Gtk.Orientation.VERTICAL} spacing={6}>
          {group.notifications.map((notification) => (
            <NotificationCard
              notification={notification}
              onDismiss={() => notification.dismiss()}
            />
          ))}
        </box>
      </revealer>
    </box>
  )
}

interface NotificationsPanelProps {
  showHeader?: boolean
}

export function NotificationsPanel({
  showHeader = true,
}: NotificationsPanelProps = {}) {
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

          const groups = groupNotifications(notifs)

          return (
            <box orientation={Gtk.Orientation.VERTICAL} spacing={0} hexpand>
              {showHeader && (
                <box class="nc-notifs-header" hexpand>
                  <label
                    class="nc-notifs-label"
                    label={`Notifications · ${notifs.length}`}
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
              )}
              <box orientation={Gtk.Orientation.VERTICAL} spacing={6} hexpand>
                {groups.map((group) => (
                  <NotificationGroup group={group} />
                ))}
              </box>
            </box>
          )
        }}
      </With>
    </box>
  )
}
