import { Accessor, createComputed } from "ags"

export function createRunningComputed(
  runingState: Accessor<"paused" | "runing" | "stopped">,
) {
  return {
    isRunning: createComputed(() => runingState() === "runing"),
    isPaused: createComputed(() => runingState() === "paused"),
    isStopped: createComputed(() => runingState() === "stopped"),
  }
}

export function formatTime(seconds: number, showHours = true): string {
  const hrs = Math.floor(seconds / 3600)
  const mins = Math.floor((seconds % 3600) / 60)
  const secs = Math.floor(seconds % 60)

  const pad = (n: number) => n.toString().padStart(2, "0")

  if (showHours) {
    return `${pad(hrs)}:${pad(mins)}:${pad(secs)}`
  }

  return `${pad(mins + hrs * 60)}:${pad(secs)}`
}
