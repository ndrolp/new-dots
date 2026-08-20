import AstalWp from "gi://AstalWp"
import { createBinding, createComputed, For, With } from "ags"
import { Gtk } from "ags/gtk4"
import PopUp from "../../common/PopUp"
import { getVolumeIcon } from "../../../utils/audio"

function SinkRow({ sink }: { sink: AstalWp.Endpoint }) {
  const description = createBinding(sink, "description")
  const name = createBinding(sink, "name")
  const isDefault = createBinding(sink, "isDefault")

  return (
    <button
      class={createComputed(() => `audio-sink ${isDefault() ? "active" : ""}`)}
      onClicked={() => sink.set_is_default(true)}
    >
      <box spacing={8}>
        <label class="sink-icon" label="󰓃" />
        <label
          class="sink-name"
          hexpand
          halign={Gtk.Align.START}
          label={createComputed(
            () => description() || name() || "Unknown output",
          )}
        />
        <label
          class="sink-selected"
          label={createComputed(() => (isDefault() ? "󰄬" : ""))}
        />
      </box>
    </button>
  )
}

function VolumeControls({ speaker }: { speaker: AstalWp.Endpoint }) {
  const volume = createBinding(speaker, "volume")
  const muted = createBinding(speaker, "mute")

  return (
    <box class="audio-volume" spacing={8}>
      <button
        class="mute-button"
        tooltipText={createComputed(() => (muted() ? "Unmute" : "Mute"))}
        onClicked={() => speaker.set_mute(!muted())}
      >
        <label label={createComputed(() => getVolumeIcon(volume(), muted()))} />
      </button>
      <slider
        hexpand
        value={volume}
        min={0}
        max={1.5}
        onValueChanged={(slider) => speaker.set_volume(slider.value)}
      />
      <label
        class="volume-percentage"
        label={createComputed(() => `${Math.round(volume() * 100)}%`)}
      />
    </box>
  )
}

export default function AudioPopup({ audio }: { audio: AstalWp.Audio }) {
  const speaker = createBinding(audio, "defaultSpeaker")
  const speakers = createBinding(audio, "speakers")

  return (
    <PopUp cssClass="audio-popup" transitionDuration={300}>
      <box
        class="audio-popup-content"
        orientation={Gtk.Orientation.VERTICAL}
        spacing={16}
      >
        <label
          class="audio-popup-title"
          halign={Gtk.Align.START}
          label="Audio Output"
        />
        <With value={speaker}>
          {(defaultSpeaker) => <VolumeControls speaker={defaultSpeaker} />}
        </With>
        <box
          class="audio-sinks"
          orientation={Gtk.Orientation.VERTICAL}
          spacing={8}
        >
          <For each={speakers}>{(sink) => <SinkRow sink={sink} />}</For>
        </box>
      </box>
    </PopUp>
  )
}
