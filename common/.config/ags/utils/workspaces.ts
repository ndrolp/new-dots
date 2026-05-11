import AstalHyprland from "gi://AstalHyprland"
import { ShellSettings } from "./SettingsManager"
import { execAsync } from "ags/process"

export function placeWorkspaceInMonitor() {
  const hypr = AstalHyprland.get_default()
  const settings = ShellSettings.getInstance()

  const monitors = settings.workspaces.monitors

  console.log("Monitors configuration:", monitors)

  for (const [monitorName, config] of Object.entries(monitors)) {
    const monitor = hypr.get_monitors().find((m) => m.model === monitorName)

    if (!monitor) {
      console.log(`Monitor ${monitorName} not found`)
      continue
    }

    console.log(`Found monitor ${monitorName} (${monitor.description})`)

    execAsync([
      `./scripts/workspacesDisplacer.sh`,
      `desc:${monitor.description}`,
      String(config.from),
      String(config.to),
    ])
      .then(() => {
        console.log(
          `Moved workspaces ${config.from}-${config.to} to ${monitorName}`,
        )
      })
      .catch((err) => {
        console.error(`Failed moving workspaces for ${monitorName}:`, err)
      })
  }
}
