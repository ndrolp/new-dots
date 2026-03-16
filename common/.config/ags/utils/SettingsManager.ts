import { readFile, readFileAsync, writeFile } from "ags/file"
import {
  IBarAppearence,
  ILogSettings,
  INowPlayingConfig,
  IShellSettings,
  IWidgetSettings,
  WorkspacesConfig,
} from "../config/types"
import {
  BAR_APPEARENCES,
  DEFAULT_BAR_APPEARENCE,
  SHEL_THEME,
} from "./settings/DefaultBarAppearences"

export class ShellSettings implements IShellSettings {
  private static instance: ShellSettings

  log: ILogSettings
  theme: SHEL_THEME
  barAppearence: IBarAppearence
  workspaces: WorkspacesConfig
  nowPlaying: INowPlayingConfig
  widgets: IWidgetSettings

  private constructor(data?: Partial<IShellSettings>) {
    this.theme = data?.theme ?? "catppuccin"

    this.log = {
      enabled: data?.log?.enabled ?? false,
      level: data?.log?.level ?? "log",
    }

    this.barAppearence = {
      layout: data?.barAppearence?.layout ?? "default",
      island: data?.barAppearence?.island ?? false,
      compact: data?.barAppearence?.compact ?? false,
      rounding: data?.barAppearence?.rounding ?? "md",
      float: data?.barAppearence?.float ?? true,
      showBorder: data?.barAppearence?.showBorder ?? true,
    }

    this.workspaces = {
      monitors: data?.workspaces?.monitors ?? {},
      displayType: data?.workspaces?.displayType ?? "dots",
      icons: data?.workspaces?.icons ?? {},
    }

    this.nowPlaying = {
      showControls: data?.nowPlaying?.showControls ?? true,
      preferedClients: data?.nowPlaying?.preferedClients ?? [],
      ignoreClients: data?.nowPlaying?.ignoreClients ?? [],
    }

    this.widgets = {
      default: data?.widgets?.default ?? {
        left: [["clock", "now-playing"]],
        center: [["workspaces"]],
        right: [["network", "audio", "battery"]],
      },
      flush: data?.widgets?.flush ?? {
        left: [["workspaces"]],
        center: [["clock"]],
        right: [["now-playing", "network", "audio", "battery"]],
      },
    }
  }

  // =========================
  // Singleton accessor
  // =========================
  static getInstance(): ShellSettings {
    if (!ShellSettings.instance) {
      ShellSettings.instance = ShellSettings.load()
    }
    return ShellSettings.instance
  }

  // =========================
  // Load from JSON
  // =========================
  private static load(): ShellSettings {
    try {
      const raw = readFile("settings.json")
      const parsed = JSON.parse(raw)
      return new ShellSettings(parsed)
    } catch (err) {
      console.error("Failed to load settings, using defaults.", err)
      return new ShellSettings()
    }
  }

  // =========================
  // Save to JSON
  // =========================
  save(): void {
    const data = {
      $schema: "./settings.schema.json", // <-- injected schema

      theme: this.theme,
      barAppearence: this.barAppearence,
      workspaces: this.workspaces,
      nowPlaying: this.nowPlaying,
      log: this.log,
      widgets: this.widgets,
    }

    const dataToSave = JSON.stringify(data, null, 4)
    writeFile("settings.json", dataToSave)
  }

  shouldUseClient(client: string): boolean {
    if (this.nowPlaying.ignoreClients.includes(client)) return false
    if (this.nowPlaying.preferedClients.length === 0) return true
    return this.nowPlaying.preferedClients.includes(client)
  }

  setAppearence(appearence: DEFAULT_BAR_APPEARENCE) {
    this.barAppearence = BAR_APPEARENCES[appearence]
    this.save()
  }

  setColorscheme(theme: SHEL_THEME) {
    this.theme = theme
    this.save()
  }
}
