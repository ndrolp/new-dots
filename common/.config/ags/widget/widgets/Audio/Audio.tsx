import AstalWp from "gi://AstalWp"
import { createBinding, createComputed, With } from "ags"
import { getVolumeBar, getVolumeIcon } from "../../../utils/audio"
import { ShellSettings } from "../../../utils/SettingsManager"
import AudioPopup from "./AudioPopup"

export default function AudioButton() {
  const audio = AstalWp.get_default().audio
  const settings = ShellSettings.getInstance()
  const defaultSpeaker = createBinding(audio, "defaultSpeaker")

  return (
    <menubutton class="bar-icon">
      <box>
        <With value={defaultSpeaker}>
          {(speaker) => {
            const volume = createBinding(speaker, "volume")
            const muted = createBinding(speaker, "mute")
            const volumeData = createComputed(() => ({
              volume: volume(),
              muted: muted(),
            }))

            return (
              <box class="audio-button">
                <box
                  class={createComputed(() => {
                    const data = volumeData()
                    return `data-container ${data.muted ? "muted" : ""} ${data.volume === 0 ? "silence" : ""}`
                  })}
                >
                  <label
                    class="icon"
                    label={createComputed(() => {
                      const data = volumeData()
                      return getVolumeIcon(data.volume, data.muted)
                    })}
                  />
                  <label
                    visible={createComputed(
                      () =>
                        !settings.barAppearence.verbose &&
                        volumeData().volume !== 0,
                    )}
                    class="bar"
                    label={createComputed(() => getVolumeBar(volumeData().volume))}
                  />
                  <label
                    visible={settings.barAppearence.verbose}
                    class="percentage"
                    label={createComputed(
                      () => `${Math.round(volumeData().volume * 100)}%`,
                    )}
                  />
                </box>
              </box>
            )
          }}
        </With>
      </box>
      <AudioPopup audio={audio} />
    </menubutton>
  )
}
