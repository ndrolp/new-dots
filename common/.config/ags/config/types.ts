export interface IShellSettings {
  theme: "catppuccin" | "gruvbox-dark" | "monochrome-blue-dark"
  barAppearence: IBarAppearence
  workspaces: WorkspacesConfig
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
  rounding: "lg" | "sm" | "md" | "none" | "full"
}
