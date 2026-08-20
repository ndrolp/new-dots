import Mpris from "gi://AstalMpris?version=0.1"
import PopUp from "../../common/PopUp"
import { Gtk } from "ags/gtk4"
import Adw from "gi://Adw"
import Gio from "gi://Gio?version=2.0"
import { createBinding, createComputed, With } from "ags"
import { truncateString } from "../../../utils/stringFunctions"
import { ShellSettings } from "../../../utils/SettingsManager"

export function secondsToMMSS(totalSeconds: number): string {
  const safe = Math.max(0, Math.round(totalSeconds))

  const minutes = Math.floor(safe / 60)
  const seconds = safe % 60

  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`
}

export function PlayingDetails({ player }: { player: Mpris.Player }) {
  if (!player) return <box visible={false} />
  const title = createBinding(player, "title")
  const artist = createBinding(player, "artist")
  const coverArt = createBinding(player, "coverArt")
  const album = createBinding(player, "album")
  const duration = createBinding(player, "length")
  const position = createBinding(player, "position")
  const playbackStatus = createBinding(player, "playback_status")
  const canGoPrevious = createBinding(player, "can_go_previous")
  const canGoNext = createBinding(player, "can_go_next")
  const canControl = createBinding(player, "can_control")
  const canSeek = createBinding(player, "can_seek")
  const displayData = createComputed(() => {
    return {
      title: title(),
      artist: artist(),
      coverArt: coverArt(),
      album: album(),
      duration: duration(),
      position: position(),
      playbackStatus: playbackStatus(),
      canGoPrevious: canGoPrevious(),
      canGoNext: canGoNext(),
      canControl: canControl(),
      canSeek: canSeek(),
    }
  })
  const showControls = ShellSettings.getInstance().nowPlaying.showControls

  return (
    <With value={displayData}>
      {(data) => {
        return (
          <box spacing={0} orientation={Gtk.Orientation.HORIZONTAL}>
            <box spacing={5}>
              {data.coverArt ? (
                <Adw.Clamp
                  valign={Gtk.Align.START}
                  maximumSize={120}
                  widthRequest={120}
                  heightRequest={120}
                >
                  <Adw.Clamp
                    orientation={Gtk.Orientation.HORIZONTAL}
                    maximumSize={120}
                  >
                    <Gtk.Picture
                      class="picture"
                      contentFit={Gtk.ContentFit.COVER}
                      file={Gio.file_new_for_path(data.coverArt)}
                    />
                  </Adw.Clamp>
                </Adw.Clamp>
              ) : (
                <box visible={false} />
              )}
              <box
                class={"song-info"}
                hexpand
                vexpand
                halign={Gtk.Align.START}
                orientation={Gtk.Orientation.VERTICAL}
                spacing={1}
              >
                <label
                  halign={Gtk.Align.START}
                  class={"song-title"}
                  label={truncateString(data.title, 40)}
                />
                <label
                  halign={Gtk.Align.START}
                  class={"song-artist"}
                  label={data.artist}
                />
                <label
                  halign={Gtk.Align.START}
                  class={"song-album"}
                  label={data.album}
                />
                <slider
                  valign={Gtk.Align.END}
                  sensitive={data.canSeek && data.duration > 0}
                  value={data.duration > 0 ? data.position / data.duration : 0}
                  min={0}
                  max={1}
                  widthRequest={200}
                  onValueChanged={(val) => {
                    player.set_position(val.value * data.duration)
                  }}
                />
                <centerbox>
                  <label
                    $type="start"
                    halign={Gtk.Align.START}
                    class={"song-position"}
                    label={secondsToMMSS(data.position)}
                  />
                  <label
                    $type="end"
                    halign={Gtk.Align.END}
                    class={"song-position"}
                    label={secondsToMMSS(data.duration)}
                  />
                  {showControls && (
                    <box
                      $type="center"
                      class="playback-controls"
                      halign={Gtk.Align.CENTER}
                      spacing={4}
                    >
                      <button
                        class="playback-control"
                        sensitive={data.canControl && data.canGoPrevious}
                        tooltipText="Previous track"
                        onClicked={() => player.previous()}
                      >
                        <label label={data.canGoPrevious ? "" : ""} />
                      </button>
                      <button
                        class="playback-control play-pause"
                        sensitive={data.canControl}
                        tooltipText={
                          data.playbackStatus === Mpris.PlaybackStatus.PLAYING
                            ? "Pause"
                            : "Play"
                        }
                        onClicked={() => player.play_pause()}
                      >
                        <label
                          label={
                            data.playbackStatus === Mpris.PlaybackStatus.PLAYING
                              ? ""
                              : ""
                          }
                        />
                      </button>
                      <button
                        class="playback-control"
                        sensitive={data.canControl && data.canGoNext}
                        tooltipText="Next track"
                        onClicked={() => player.next()}
                      >
                        <label label={data.canGoPrevious ? "" : ""} />
                      </button>
                    </box>
                  )}
                </centerbox>
              </box>
            </box>
          </box>
        )
      }}
    </With>
  )
}

export default function PlayingPopUp({ player }: { player: Mpris.Player }) {
  return (
    <PopUp cssClass="playing-popup">
      <PlayingDetails player={player} />
    </PopUp>
  )
}
