import { WorkspacesConfig } from "../widget/widgets/workspaces/WorkspacesSettingsType"

export interface IShellSettings {
  layout: "default" | "transparent"
  theme: "catppuccin" | "gruvbox-dark" | "monochrome-blue-dark"
  island: boolean
  workspaces: WorkspacesConfig
}
