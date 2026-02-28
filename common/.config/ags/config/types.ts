import { WorkspacesConfig } from "../widget/widgets/workspaces/WorkspacesSettingsType"

export interface IShellSettings {
  layout: "default" | "transparent"
  theme: "catppuccin" | "gruvbox-dark"
  island: boolean
  workspaces: WorkspacesConfig
}
