import AstalWp from "gi://AstalWp"
import { createBinding, With } from "ags"
export default function AudioButton() {
  const audioServer = AstalWp.get_default().get_default_speaker()
  const audio = createBinding(audioServer, "name")
  const esto = AstalWp.get_default().audio.defaultSpeaker

  console.log({
    name: audioServer.volume,
    server: audioServer,
    esto: esto.name,
  })

  return (
    <button class="bar-icon audio-button" margin_end={5}>
      <label label="" />
    </button>
  )
}
