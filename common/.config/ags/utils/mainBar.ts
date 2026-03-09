import { ShellSettings } from "./SettingsManager"

export function getWindowSettingsCssClasses() {
  const SETTINGS = ShellSettings.getInstance()
  let cssClasses: string[] = []

  cssClasses.push(SETTINGS.theme ?? "catppuccin")
  cssClasses.push(SETTINGS.barAppearence.layout ?? "default")
  cssClasses.push(`layout-${SETTINGS.barAppearence.layout ?? "default"}`)
  cssClasses.push(`rounding-${SETTINGS.barAppearence.rounding ?? "md"}`)
  cssClasses.push(SETTINGS.barAppearence.compact ? "compact" : "")
  cssClasses.push(SETTINGS.barAppearence.float ? "float" : "flush")
  cssClasses.push(SETTINGS.barAppearence.island ? "island" : "")
  cssClasses.push(
    SETTINGS.barAppearence.showBorder ? "show-border" : "no-border",
  )

  const valueToReturn = cssClasses.join(" ")

  console.log({ CssClasses: valueToReturn })

  return cssClasses.join(" ")
}
