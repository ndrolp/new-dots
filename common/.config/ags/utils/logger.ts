import { ShellSettings } from "./SettingsManager"

export default class Logger {
  private static instance: Logger
  private static logLevel: "log" | "error" | "warn" = "log"
  private static enabled: boolean = true

  private constructor() {
    Logger.logLevel = ShellSettings.getInstance().log.level || Logger.logLevel
  }

  public static getInstance(): Logger {
    if (!Logger.instance) {
      Logger.instance = new Logger()
    }
    return Logger.instance
  }

  public log(...args: any[]) {
    const timestamp = new Date().toISOString()
    if (Logger.enabled && Logger.logLevel === "log") {
      console.log(`[LOG] - ${timestamp}:`, ...args)
    }
  }

  public warn(...args: any[]) {
    const timestamp = new Date().toISOString()
    if (
      (Logger.enabled && Logger.logLevel === "log") ||
      Logger.logLevel === "warn"
    ) {
      console.warn(`[WARN] - ${timestamp}:`, ...args)
    }
  }

  public error(...args: any[]) {
    const timestamp = new Date().toISOString()
    if (
      Logger.enabled &&
      (Logger.logLevel === "log" ||
        Logger.logLevel === "warn" ||
        Logger.logLevel === "error")
    ) {
      console.error(`[ERROR] - ${timestamp}:`, ...args)
    }
  }

  public separator() {
    if (Logger.enabled && Logger.logLevel === "log") {
      console.log(`----------------------------------------`)
    }
  }
}
