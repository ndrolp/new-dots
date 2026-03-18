import { Gtk } from "ags/gtk4"
import { getWindowSettingsCssClasses } from "../../../utils/mainBar"
import { createState } from "gnim"

export default function TimerButton({}) {
  const [isPopoverOpen, setIsPopoverOpen] = createState(false)
  return (
    <menubutton class="timer-button bar-icon">
      <box class="timer-button-container">
        <label class="bar-icon-icon" label="󰞌" valign={Gtk.Align.CENTER} />
        <label class="bar-icon-label" label="00:00" valign={Gtk.Align.CENTER} />
      </box>
      <popover
        has_arrow={false}
        onNotifyVisible={(p) => setIsPopoverOpen(p.visible)}
      >
        <revealer
          revealChild={isPopoverOpen}
          transition_type={Gtk.RevealerTransitionType.SLIDE_DOWN}
        >
          <box
            orientation={Gtk.Orientation.VERTICAL}
            class={`timer-popover window ${getWindowSettingsCssClasses()}`}
          >
            <box orientation={Gtk.Orientation.VERTICAL} class="timer-info">
              <label class="title" label="Create a Timer" />
            </box>
            <centerbox>
              <button class="default-timers" $type="start" label="" />
              <label $type="center" class="time" label="00:00:00" />
              <button class="default-timers" $type="end" label="" />
            </centerbox>
            <box spacing={5}>
              <button class="time-modifier-button" label="+1min" />
              <button class="time-modifier-button" label="-1min" />
              <button class="time-modifier-button" label="+10min" />
              <button class="time-modifier-button" label="-10min" />
            </box>
            <button class={`run-button ${"start"}`}>
              <label label="Start Timer" />
            </button>
          </box>
        </revealer>
      </popover>
    </menubutton>
  )
}
