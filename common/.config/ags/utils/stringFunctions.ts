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

export function capitalizeEachWord(str: string) {
  if (typeof str !== "string") return ""
  return str
    .split(" ")
    .map((word) => {
      if (word.length === 0) return ""
      return word[0].toUpperCase() + word.slice(1).toLowerCase()
    })
    .join(" ")
}
