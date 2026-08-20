import Mpris from "gi://AstalMpris"
import { createBinding, createComputed, With } from "ags"
import { Gtk } from "ags/gtk4"
import { getPlayerIcon } from "../../../utils/audio"
import { truncateString } from "../../../utils/stringFunctions"
import PlayingPopUp from "./PlayingPopup"

export default function NowPlaying() {
  const spotify = Mpris.Player.new("spotify")
  const defaulMpris = Mpris.get_default()
  const defaultPlayers = createBinding(defaulMpris, "players")
  const spotifyAvailable = createBinding(spotify, "available")

  const data = createComputed(() => {
    return { players: defaultPlayers(), spotifyAvailable: spotifyAvailable() }
  })

  return (
    <box>
      <With value={data}>
        {(barData) => {
          return (
            <revealer
              transitionType={Gtk.RevealerTransitionType.SLIDE_LEFT}
              revealChild={createComputed(() => {
                if (spotifyAvailable()) return true
                const players = defaultPlayers()
                if (players.length > 0 && (players?.[0].title ?? false))
                  return players[0].title !== ""
                return false
              })}
            >
              <box
                visible={barData.spotifyAvailable || barData.players.length > 0}
              >
                <menubutton class="now-playing bar-icon">
                  <Gtk.EventControllerMotion />
                  {barData.spotifyAvailable ? (
                    <PlayerBarLine player={spotify} />
                  ) : (
                    <box>
                      {barData.players.length > 0 ? (
                        <PlayerBarLine player={barData.players[0]} />
                      ) : (
                        <box visible={false} />
                      )}
                    </box>
                  )}
                  <PlayingPopUp
                    player={
                      barData.spotifyAvailable ? spotify : barData.players[0]
                    }
                  />
                </menubutton>
              </box>
            </revealer>
          )
        }}
      </With>
    </box>
  )
}

export function PlayerBarLine({ player }: { player: Mpris.Player }) {
  const title = createBinding(player, "title")
  const identity = createBinding(player, "identity")
  const status = createBinding(player, "playback_status")

  const playerData = createComputed(() => {
    return {
      title: title(),
      identity: identity(),
      status: status(),
    }
  })

  return (
    <box visible={createComputed(() => title() !== "")}>
      <With value={playerData}>
        {(data) => {
          const playbackStatus = data.status
          const cssPlaybackClass =
            playbackStatus === Mpris.PlaybackStatus.PLAYING
              ? "playing"
              : playbackStatus === Mpris.PlaybackStatus.STOPPED
                ? "stopped"
                : playbackStatus === Mpris.PlaybackStatus.PAUSED
                  ? "paused"
                  : ""
          return (
            <box class={cssPlaybackClass}>
              <label
                halign={Gtk.Align.CENTER}
                label={getPlayerIcon(data.identity, data.title)}
              />
              <label
                halign={Gtk.Align.CENTER}
                label={truncateString(data.title, 30)}
              />
            </box>
          )
        }}
      </With>
    </box>
  )
}
