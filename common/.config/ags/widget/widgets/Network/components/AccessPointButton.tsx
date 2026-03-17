import { Gtk } from "ags/gtk4"
import { getAccessPointIcon } from "../../../../utils/network"
import { createState } from "ags"
import AstalNetwork from "gi://AstalNetwork"
import { ShellSettings } from "../../../../utils/SettingsManager"

export const AccessPointButton = ({
  accessPoint,
}: {
  accessPoint: AstalNetwork.AccessPoint
}) => {
  const [passwordEntryRevealed, passwordEntryRevealedSetter] =
    createState(false)
  const settings = ShellSettings.getInstance()
  return (
    <box
      cssClasses={[
        "acces-point-button",
        `rounding-${settings.barAppearence.rounding}`,
      ]}
      orientation={Gtk.Orientation.VERTICAL}
    >
      <box orientation={Gtk.Orientation.HORIZONTAL}>
        <button
          hexpand={true}
          onClicked={() => {
            passwordEntryRevealedSetter(!passwordEntryRevealed.peek())
          }}
        >
          <label
            halign={Gtk.Align.START}
            label={`${getAccessPointIcon(accessPoint)}    ${accessPoint.ssid}`}
          />
        </button>
      </box>
      <revealer
        revealChild={passwordEntryRevealed}
        transitionDuration={200}
        transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
      >
        <label label="PASSWORD GOES HERE" />
      </revealer>
    </box>
  )
}
