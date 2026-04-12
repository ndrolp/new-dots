import AstalWp from "gi://AstalWp"
import { createBinding, createComputed, With } from "ags"
import { getVolumeBar, getVolumeIcon } from "../../../utils/audio"
import { ShellSettings } from "../../../utils/SettingsManager"

export default function AudioButton() {
  const wp = AstalWp.get_default().audio.defaultSpeaker
  const settings = ShellSettings.getInstance()
  const wpVolume = createBinding(wp, "volume")
  const wpMuted = createBinding(wp, "mute")

  const volumeData = createComputed(() => {
    return { volume: wpVolume(), muted: wpMuted() }
  })

  return (
    <menubutton class="bar-icon">
      <With value={volumeData}>
        {(volumeData) => {
          return (
            <box class="audio-button">
              <box
                class={`data-container ${volumeData.muted ? "muted" : ""} ${volumeData.volume === 0 ? "silence" : ""}`}
              >
                <label
                  class="icon"
                  label={getVolumeIcon(volumeData.volume, volumeData.muted)}
                />
                <label
                  visible={
                    !settings.barAppearence.verbose && volumeData.volume !== 0
                  }
                  class="bar"
                  label={getVolumeBar(volumeData.volume)}
                />
                <label
                  visible={settings.barAppearence.verbose}
                  class="percentage"
                  label={`${Math.round(volumeData.volume * 100)}%`}
                />
              </box>
            </box>
          )
        }}
      </With>
    </menubutton>
  )
}
