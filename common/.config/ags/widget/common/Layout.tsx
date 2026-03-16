import { ShellSettings } from "../../utils/SettingsManager"
import LayoutGenerator from "./LayoutGenerator"
import { Gdk } from "ags/gtk4"

export default function Layout({ monitor }: { monitor: Gdk.Monitor }) {
  const settings = ShellSettings.getInstance()
  console.log({ WIDGETS: settings.widgets })
  if (!settings.barAppearence.float) {
    return (
      <LayoutGenerator
        layout={settings.widgets.flush ?? settings.widgets.default}
        monitor={monitor}
      />
    )
  } else if (settings.barAppearence.island === true) {
    return (
      <LayoutGenerator
        layout={settings.widgets.island ?? settings.widgets.default}
        monitor={monitor}
      />
    )
  } else {
    return (
      <LayoutGenerator layout={settings.widgets.default} monitor={monitor} />
    )
  }
}
