.pragma library

function truncate(text, maxLength) {
  if (typeof text !== "string") return ""
  if (text.length <= maxLength) return text
  if (maxLength <= 3) return ".".repeat(maxLength)
  return text.slice(0, maxLength - 3) + "..."
}

function formatTimer(seconds, longFormat) {
  var safeSeconds = Math.max(0, Math.floor(seconds))
  var hours = Math.floor(safeSeconds / 3600)
  var minutes = Math.floor((safeSeconds % 3600) / 60)
  var secs = safeSeconds % 60

  if (longFormat) {
    if (hours > 0) {
      return pad(hours) + ":" + pad(minutes) + ":" + pad(secs)
    }
    return pad(minutes) + ":" + pad(secs)
  }

  return pad(hours) + ":" + pad(minutes) + ":" + pad(secs)
}

function pad(value) {
  return value < 10 ? "0" + value : String(value)
}
