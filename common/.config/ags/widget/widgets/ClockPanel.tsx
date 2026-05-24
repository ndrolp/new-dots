import { Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import Notifd from "gi://AstalNotifd"
import CustomWindow from "../common/Window"
import { WINDOWS_NAMESPACES } from "../windows"
import { getClockAlign } from "../../utils/popups"
import { NotificationsPanel } from "./Dashboard/components/NotificationsPanel"

export default function ClockPanel() {
  const notifd = Notifd.get_default()
  const time = createPoll("", 1000, () =>
    new Date().toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    }),
  )

  const date = createPoll("", 60000, () =>
    new Date().toLocaleDateString([], {
      weekday: "long",
      day: "numeric",
      month: "long",
      year: "numeric",
    }),
  )

  return (
    <CustomWindow
      visible={false}
      css="clock-panel-window"
      position={getClockAlign()}
      name={WINDOWS_NAMESPACES.clock}
      namespace={WINDOWS_NAMESPACES.clock}
      resizable={false}
      hideOnFocusLoss
    >
      <box
        class="clock-panel"
        orientation={Gtk.Orientation.VERTICAL}
        spacing={12}
      >
        <box
          class="clock-panel-header"
          orientation={Gtk.Orientation.VERTICAL}
          spacing={2}
        >
          <label
            class="clock-panel-time"
            label={time}
            halign={Gtk.Align.START}
          />
          <label
            class="clock-panel-date"
            label={date}
            halign={Gtk.Align.START}
            wrap
          />
        </box>

        <box class="clock-panel-calendar-card">
          <Gtk.Calendar class="clock-panel-calendar" hexpand />
        </box>

        <box
          class="clock-panel-notifications"
          orientation={Gtk.Orientation.VERTICAL}
          spacing={8}
        >
          <box class="clock-panel-notifications-header" hexpand>
            <label
              class="clock-panel-section-title"
              label="Notifications"
              hexpand
              halign={Gtk.Align.START}
            />
            <button
              class="clock-panel-clear-button"
              onClicked={() =>
                notifd.get_notifications().forEach((notification) =>
                  notification.dismiss(),
                )
              }
              tooltipText="Clear all"
            >
              <label label="Clear" />
            </button>
          </box>
          <scrolledwindow
            class="clock-panel-scroll"
            hscrollbar_policy={Gtk.PolicyType.NEVER}
            vscrollbar_policy={Gtk.PolicyType.AUTOMATIC}
          >
            <box
              class="clock-panel-scroll-inner"
              orientation={Gtk.Orientation.VERTICAL}
            >
              <NotificationsPanel showHeader={false} />
            </box>
          </scrolledwindow>
        </box>
      </box>
    </CustomWindow>
  )
}
