import { SHEL_THEME } from "../utils/settings/DefaultBarAppearences"

export interface IShellSettings {
  theme: SHEL_THEME
  barAppearence: IBarAppearence
  workspaces: WorkspacesConfig
  nowPlaying: INowPlayingConfig
}

export interface WorkspaceRange {
  minWorkspaces: number
  from: number
  to: number
}

export type WorkspacesConfig = {
  monitors: Record<string, WorkspaceRange>
}

export interface IBarAppearence {
  layout: "default" | "transparent"
  island: boolean
  compact: boolean
  float: boolean
  rounding: "lg" | "sm" | "md" | "none" | "full"
}

export interface INowPlayingConfig {
  showControls: boolean
  preferedClients: string[]
  ignoreClients: string[]
}
