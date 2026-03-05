import { IBarAppearence } from "../../config/types"

export type DEFAULT_BAR_APPEARENCE =
  | "default"
  | "compact-island"
  | "simple-island"
  | "full-compact"
  | "separated-island"
  | "separated-full"

export type SHEL_THEME =
  | "catppuccin"
  | "gruvbox-dark"
  | "monochrome-blue-dark"
  | "nord"

export const SHELL_THEMES_BINDER: Record<string, SHEL_THEME> = {
  catppuccin: "catppuccin",
  gruvboxdark: "gruvbox-dark",
}

export const BAR_APPEARENCES: Record<DEFAULT_BAR_APPEARENCE, IBarAppearence> = {
  "full-compact": {
    layout: "default",
    compact: true,
    island: false,
    rounding: "sm",
  },
  "simple-island": {
    layout: "default",
    compact: false,
    island: true,
    rounding: "md",
  },
  "compact-island": {
    layout: "default",
    compact: true,
    island: true,
    rounding: "full",
  },
  default: {
    layout: "default",
    compact: false,
    island: false,
    rounding: "sm",
  },
  "separated-island": {
    layout: "transparent",
    compact: false,
    island: true,
    rounding: "md",
  },
  "separated-full": {
    layout: "transparent",
    compact: true,
    island: false,
    rounding: "md",
  },
}
