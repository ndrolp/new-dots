import { Gtk, Gdk } from "ags/gtk4"
import { createComputed, With } from "ags"
import { execAsync } from "ags/process"
import Adw from "gi://Adw"
import Gio from "gi://Gio?version=2.0"
import { buildRows } from "../lib/layout"

export interface WallpapersBoxProps {
  wallpapers: string[]
  direction?: WallpapersBoxOrientation
  monitorName: string
  path: string
  thumbnailPath?: string
}

export type WallpapersBoxOrientation = "vertical" | "horizontal"

export default function WallpapersBox({
  wallpapers,
  monitorName,
  path,
  thumbnailPath = undefined,
  direction = "horizontal",
}: WallpapersBoxProps) {
  const width = direction === "horizontal" ? 100 : 100
  const height = direction === "horizontal" ? 100 : 100
  return (
    <box>
      <box>
        <With
          value={createComputed(() =>
            buildRows(wallpapers, direction === "vertical" ? 5 : 5),
          )}
        >
          {(rows: string[][]) => (
            <Gtk.Box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
              {rows.map((row) => (
                <box spacing={10}>
                  {row.map((wallpaper) => (
                    <button
                      onClicked={() => {
                        execAsync([
                          "awww",
                          "img",
                          "-o",
                          monitorName,
                          `${path}/${wallpaper}`,
                          "--transition-type",
                          "wipe",
                        ])
                      }}
                      cursor={Gdk.Cursor.new_from_name("pointer", null)}
                    >
                      <Adw.Clamp
                        valign={Gtk.Align.START}
                        maximumSize={
                          direction === "horizontal" ? height : width
                        }
                        widthRequest={width}
                        heightRequest={height}
                      >
                        <Adw.Clamp
                          orientation={
                            direction === "horizontal"
                              ? Gtk.Orientation.HORIZONTAL
                              : Gtk.Orientation.VERTICAL
                          }
                          maximumSize={
                            direction === "horizontal" ? width : height
                          }
                        >
                          <Gtk.Picture
                            class="picture"
                            contentFit={Gtk.ContentFit.COVER}
                            file={Gio.file_new_for_path(
                              `${thumbnailPath ? thumbnailPath : path}/${wallpaper}`,
                            )}
                          />
                        </Adw.Clamp>
                      </Adw.Clamp>
                    </button>
                  ))}
                </box>
              ))}
            </Gtk.Box>
          )}
        </With>
      </box>
    </box>
  )
}
