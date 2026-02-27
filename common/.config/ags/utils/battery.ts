import AstalBattery from "gi://AstalBattery"

export function getBatteryIcon(state: AstalBattery.State, percentage: number) {
  const percent = percentage
  if (state === AstalBattery.State.CHARGING) {
    if (percent <= 0.1) {
      return "󰢜"
    } else if (percent <= 0.2) {
      return "󰂆"
    } else if (percent <= 0.3) {
      return "󰂇"
    } else if (percent <= 0.4) {
      return "󰂈"
    } else if (percent <= 0.5) {
      return "󰢝"
    } else if (percent <= 0.6) {
      return "󰂉"
    } else if (percent <= 0.7) {
      return "󰢞"
    } else if (percent <= 0.8) {
      return "󰂊"
    } else if (percent <= 0.9) {
      return "󰂋"
    } else {
      return "󰂅"
    }
  } else {
    if (percent <= 0.1) {
      return "󰁺"
    } else if (percent <= 0.2) {
      return "󰁻"
    } else if (percent <= 0.3) {
      return "󰁼"
    } else if (percent <= 0.4) {
      return "󰁽"
    } else if (percent <= 0.5) {
      return "󰁾"
    } else if (percent <= 0.6) {
      return "󰁿"
    } else if (percent <= 0.7) {
      return "󰂀"
    } else if (percent <= 0.8) {
      return "󰂁"
    } else if (percent <= 0.9) {
      return "󰂂"
    } else {
      return "󰁹"
    }
  }
}
export function secondsToTime(seconds: number) {
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)

  const hourText = hours > 0 ? `${hours} ${hours === 1 ? "hour" : "hours"}` : ""

  const minuteText =
    minutes > 0 ? `${minutes} ${minutes === 1 ? "minute" : "minutes"}` : ""

  if (hours > 0 && minutes > 0) {
    return `${hourText} and ${minuteText}`
  }

  return hourText || minuteText || "0 minutes"
}
