export type SHEL_THEME =
  | "catppuccin"
  | "gruvbox-dark"
  | "monochrome-blue-dark"
  | "nord"

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
  island: boolean
  compact: boolean
  float: boolean
  showBorder: boolean
  rounding: "lg" | "sm" | "md" | "none" | "full"
}

export interface INowPlayingConfig {
  showControls: boolean
  preferedClients: string[]
  ignoreClients: string[]
}

export interface IShellSettings {
  theme: SHEL_THEME
  barAppearence: IBarAppearence
  workspaces: WorkspacesConfig
  nowPlaying: INowPlayingConfig
  log: ILogSettings
}
