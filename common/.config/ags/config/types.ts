export type SHEL_THEME =
  | "catppuccin"
  | "gruvbox-dark"
  | "transparent-catppuccin"
  | "nord"
  | "tokyonight"

export interface ILogSettings {
  enabled: boolean
  level: "log" | "error" | "warn"
}

export interface WorkspaceRange {
  minWorkspaces: number
  from: number
  to: number
}

export type WorkspacesConfig = {
  monitors: Record<string, WorkspaceRange>
  displayType: "dots" | "numbers" | "icons-filled" | "icons"
  icons: {
    [key: string]: string
  }
}

export interface IBarAppearence {
  layout:
    | "default"
    | "transparent"
    | "separated-islands"
    | "slanted-separated-island"
  position: "top" | "bottom"
  island: boolean
  compact: boolean
  verbose: boolean
  float: boolean
  showBorder: boolean
  rounding: "lg" | "sm" | "md" | "none" | "full"
}

export interface INowPlayingConfig {
  showControls: boolean
  preferedClients: string[]
  ignoreClients: string[]
}

export type AVAILABLE_WIDGETS =
  | "battery"
  | "audio"
  | "network"
  | "now-playing"
  | "current-app"
  | "workspaces"
  | "clock"
  | "timer"
  | "dashboard"
  | "tray"

export interface IWidgetLayout {
  left: AVAILABLE_WIDGETS[][]
  center: AVAILABLE_WIDGETS[][]
  right: AVAILABLE_WIDGETS[][]
}

export interface IWidgetSettings {
  default: IWidgetLayout
  flush?: IWidgetLayout
  island?: IWidgetLayout
}

export interface IShellSettings {
  theme: SHEL_THEME
  barAppearence: IBarAppearence
  workspaces: WorkspacesConfig
  nowPlaying: INowPlayingConfig
  log: ILogSettings
  widgets: IWidgetSettings
}
