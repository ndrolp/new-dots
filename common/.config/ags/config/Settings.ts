import { readFile } from "ags/file"
import { IShellSettings } from "./types"

export const SETTINGS: IShellSettings = JSON.parse(readFile("settings.json"))
