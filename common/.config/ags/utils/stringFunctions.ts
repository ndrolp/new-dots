export function truncateString(str: string, maxLength: number) {
  if (typeof str !== "string") return ""
  if (maxLength <= 0) return ""

  if (str.length <= maxLength) {
    return str
  }

  if (maxLength <= 3) {
    return ".".repeat(maxLength)
  }

  return str.slice(0, maxLength - 3) + "..."
}
