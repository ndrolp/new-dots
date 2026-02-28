import { WorkspacesConfig } from "../widget/widgets/workspaces/WorkspacesSettingsType"

export interface IShellSettings {
  layout: "default" | "transparent"
  workspaces: WorkspacesConfig
}
