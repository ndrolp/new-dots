import { IBarAppearence, SHEL_THEME } from "../../config/types"

export type DEFAULT_BAR_APPEARENCE =
  | "default"
  | "compact-island"
  | "simple-island"
  | "full-compact"
  | "separated-island"
  | "separated-full"

export { SHEL_THEME }

export const SHELL_THEMES_BINDER: Record<string, SHEL_THEME> = {
  catppuccin: "catppuccin",
  gruvboxdark: "gruvbox-dark",
  nord: "nord",
}

export const BAR_APPEARENCES: Record<DEFAULT_BAR_APPEARENCE, IBarAppearence> = {
  "full-compact": {
    layout: "default",
    position: "top",
    compact: true,
    island: false,
    verbose: false,
    rounding: "sm",
    float: true,
    showBorder: true,
  },
  "simple-island": {
    float: true,
    showBorder: true,
    layout: "default",
    position: "top",
    compact: false,
    island: true,
    verbose: false,
    rounding: "md",
  },
  "compact-island": {
    float: true,
    showBorder: true,
    layout: "default",
    position: "top",
    compact: true,
    island: true,
    verbose: false,
    rounding: "full",
  },
  default: {
    float: true,
    showBorder: true,
    layout: "default",
    position: "top",
    compact: false,
    island: false,
    verbose: false,
    rounding: "sm",
  },
  "separated-island": {
    float: true,
    showBorder: true,
    layout: "transparent",
    position: "top",
    compact: false,
    island: true,
    verbose: false,
    rounding: "md",
  },
  "separated-full": {
    float: true,
    showBorder: true,
    layout: "transparent",
    position: "top",
    compact: true,
    island: false,
    verbose: false,
    rounding: "md",
  },
}
