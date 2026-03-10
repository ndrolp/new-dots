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
export function isPath(input: string): boolean {
  if (!input || typeof input !== "string") return false

  return (
    input.includes("/") ||
    input.includes("\\") ||
    input === "." ||
    input === ".."
  )
}
export function wrapWords(text: string, maxLength: number): string {
  const words = text.split(/\s+/)
  const lines: string[] = []
  let currentLine = ""

  for (const word of words) {
    const next = currentLine ? `${currentLine} ${word}` : word

    if (next.length <= maxLength) {
      currentLine = next
    } else {
      if (currentLine) lines.push(currentLine)
      currentLine = word
    }
  }

  if (currentLine) lines.push(currentLine)

  return lines.join("\n")
}
