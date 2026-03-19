import { Gtk } from "ags/gtk4"
import { getWindowSettingsCssClasses } from "../../../utils/mainBar"
import { createComputed, createState, onCleanup } from "ags"
import { interval } from "ags/time"
import { createRunningComputed, formatTime } from "../../../utils/timer"
import { execAsync } from "ags/process"

const DEFAULT_TIMERS = [60 * 60, 45 * 60, 30 * 60]

export default function TimerButton({}) {
  const [isPopoverOpen, setIsPopoverOpen] = createState(false)
  const [remainingTime, setRemainingTime] = createState(DEFAULT_TIMERS[0])
  const [currentTimerSelected, setCurrentTimerSelected] = createState(0)
  const [runningState, setRunningState] = createState<
    "paused" | "runing" | "stopped"
  >("stopped")

  const timer = interval(1000, () => {
    if (runningState() === "runing") {
      setRemainingTime((prev) => Math.max(prev - 1, 0))
      if (remainingTime.peek() <= 0) {
        setRunningState("stopped")
        setRemainingTime(DEFAULT_TIMERS[currentTimerSelected()])
        execAsync([
          "notify-send",
          "Timer Finished",
          "Your timer has ended.",
          "-t",
          "5000",
          "-a",
          "AGS Timer",
        ])
      }
    }
  })

  onCleanup(() => {
    timer.cancel()
  })

  const runningComputed = createRunningComputed(runningState)

  return (
    <menubutton class="timer-button bar-icon">
      <box class="timer-button-container">
        <label class="bar-icon-icon" label="󰞌" valign={Gtk.Align.CENTER} />
        <revealer
          transition_type={Gtk.RevealerTransitionType.SWING_LEFT}
          revealChild={createComputed(() => {
            return runningState() !== "stopped"
          })}
        >
          <label
            class="bar-icon-label"
            label={createComputed(() => {
              return formatTime(remainingTime(), false)
            })}
            valign={Gtk.Align.CENTER}
          />
        </revealer>
      </box>
      <popover
        has_arrow={false}
        onNotifyVisible={(p) => setIsPopoverOpen(p.visible)}
        cascadePopdown
      >
        <revealer
          revealChild={isPopoverOpen}
          transition_type={Gtk.RevealerTransitionType.SLIDE_DOWN}
        >
          <box
            orientation={Gtk.Orientation.VERTICAL}
            class={`timer-popover window ${getWindowSettingsCssClasses()}`}
            spacing={10}
          >
            <box orientation={Gtk.Orientation.VERTICAL} class="timer-info">
              <label class="title" label="Create a Timer" />
            </box>
            <centerbox>
              <button
                sensitive={createComputed(() => {
                  if (runningState() === "runing") return false
                  return currentTimerSelected() > 0
                })}
                onClicked={() => {
                  setCurrentTimerSelected((prev) => Math.max(prev - 1, 0))
                  setRemainingTime(DEFAULT_TIMERS[currentTimerSelected()])
                }}
                class="default-timers"
                $type="start"
                label=""
              />
              <label
                $type="center"
                class="time"
                label={createComputed(() => {
                  return formatTime(remainingTime(), true)
                })}
              />
              <button
                sensitive={createComputed(() => {
                  if (runningState() === "runing") return false
                  return currentTimerSelected() < DEFAULT_TIMERS.length - 1
                })}
                onClicked={() => {
                  setCurrentTimerSelected((prev) =>
                    Math.min(prev + 1, DEFAULT_TIMERS.length - 1),
                  )
                  setRemainingTime(DEFAULT_TIMERS[currentTimerSelected()])
                }}
                class="default-timers"
                $type="end"
                label=""
              />
            </centerbox>
            <box spacing={5}>
              <button
                onClicked={() => {
                  setRemainingTime(25 * 60)
                  setRunningState("runing")
                }}
                class="pomodoro-types"
                label="Pomodoro"
              />
              <button
                onClicked={() => {
                  setRemainingTime(5 * 60)
                  setRunningState("runing")
                }}
                class="pomodoro-types"
                label="Short Break"
              />
              <button
                onClicked={() => {
                  setRemainingTime(15 * 60)
                  setRunningState("runing")
                }}
                class="pomodoro-types"
                label="Long Break"
              />
            </box>
            <box spacing={5} hexpand>
              <button
                hexpand
                onClicked={() => setRemainingTime((prev) => prev + 60)}
                class="time-modifier-button"
                label="+1min"
              />
              <button
                hexpand
                onClicked={() => setRemainingTime((prev) => prev - 60)}
                class="time-modifier-button"
                label="-1min"
              />
              <button
                onClicked={() => setRemainingTime((prev) => prev + 600)}
                hexpand
                class="time-modifier-button"
                label="+10min"
              />
              <button
                onClicked={() => setRemainingTime((prev) => prev - 600)}
                hexpand
                class="time-modifier-button"
                label="-10min"
              />
            </box>
            <box homogeneous hexpand spacing={5}>
              <button
                visible={createComputed(() => !runningComputed.isStopped())}
                hexpand
                onClicked={() => {
                  setRunningState("stopped")
                  setRemainingTime(DEFAULT_TIMERS[currentTimerSelected()])
                }}
                class="run-button cancel"
              >
                <label label="Stop" />
              </button>
              <button
                visible={createComputed(() => runningComputed.isRunning())}
                hexpand
                onClicked={() => setRunningState("paused")}
                class="run-button pause"
              >
                <label label="Pause" />
              </button>
              <button
                onClicked={() => setRunningState("runing")}
                visible={createComputed(() => !runningComputed.isRunning())}
                hexpand
                class="run-button start"
              >
                <label label="Start" />
              </button>
            </box>
          </box>
        </revealer>
      </popover>
    </menubutton>
  )
}
