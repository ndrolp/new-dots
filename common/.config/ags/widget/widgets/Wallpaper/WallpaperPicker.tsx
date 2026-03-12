import { Astal, Gtk } from "ags/gtk4"
import Adw from "gi://Adw"
import AstalHyprland from "gi://AstalHyprland"
import CustomWindow from "../../common/Window"
import { createBinding, createComputed, createState, For, With } from "ags"
import Logger from "../../../utils/logger"
import { readFile, readFileAsync } from "ags/file"
import { exec, execAsync } from "ags/process"
import Gio from "gi://Gio?version=2.0"
import Gdk from "gi://Gdk?version=4.0"

const WALLPAPER_PICKER_NAMESPACE = "wallpaper_picker"

export default function WallpaperPicker() {
  const hypr = AstalHyprland.get_default()
  const Log = Logger.getInstance()
  const [horizontalWallpapers, setHorizontalWallPapers] = createState(
    [] as string[],
  )
  const [activeMonitor, setActiveMonitor] = createState(0)
  const hyprMonitors = createBinding(hypr, "monitors")
  const activeHyprMonitor = createComputed(
    () => hyprMonitors()[activeMonitor()],
  )

  //TODO: Move the locations to a settings
  const HORIZONTAL_PATH = "/home/ndrolp/Pictures/Wallpapers/Current/Horizontal"
  const VERTICAL_PATH = "/home/ndrolp/Pictures/Wallpapers/Current/Horizontal"

  execAsync(["ls", HORIZONTAL_PATH])
    .then((data) => {
      const array = data.split("\n")
      setHorizontalWallPapers(array)
    })
    .catch((error) => {
      Log.error(error)
    })

  execAsync(["ls", VERTICAL_PATH])
    .then((data) => {
      const array = data.split("\n")
      setHorizontalWallPapers(array)
    })
    .catch((error) => {
      Log.error(error)
    })

  function buildRows<T>(items: T[]): T[][] {
    const rows: T[][] = []

    items.forEach((item, i) => {
      const row = Math.floor(i / 5)

      if (!rows[row]) rows[row] = []
      rows[row].push(item)
    })

    return rows
  }

  return (
    <CustomWindow
      visible={true}
      css="wallpaper-picker"
      position={Gtk.Align.CENTER}
      name={WALLPAPER_PICKER_NAMESPACE}
      namespace={WALLPAPER_PICKER_NAMESPACE}
    >
      <box orientation={Gtk.Orientation.VERTICAL} spacing={5}>
        <box spacing={5}>
          <With value={activeMonitor}>
            {(active) => {
              return (
                <box spacing={5}>
                  {hypr.monitors.map((monitor, index) => {
                    const isActive = index === active
                    return (
                      <button
                        onClicked={() => setActiveMonitor(index)}
                        class={`monitor-button ${isActive ? "active" : ""}`}
                      >
                        <box>
                          <label label={monitor.model} />
                          <label label={" : "} />
                          <label label={monitor.name} />
                        </box>
                      </button>
                    )
                  })}
                </box>
              )
            }}
          </With>
        </box>
        <box class="card" spacing={5}>
          <With value={createComputed(() => buildRows(horizontalWallpapers()))}>
            {(rows: string[][]) => (
              <Gtk.Box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
                {rows.map((row) => (
                  <Gtk.Box spacing={8}>
                    {row.map((wallpaper) => (
                      <button
                        onClicked={() => {
                          execAsync([
                            "awww",
                            "img",
                            "-o",
                            createComputed(() => {
                              const mon = hypr.monitors[activeMonitor()]

                              return mon.name
                            })(),
                            `${HORIZONTAL_PATH}/${wallpaper}`,
                            "--transition-type",
                            "wipe",
                          ])
                        }}
                        cursor={Gdk.Cursor.new_from_name("pointer", null)}
                      >
                        <Adw.Clamp
                          valign={Gtk.Align.START}
                          maximumSize={120}
                          widthRequest={120}
                          heightRequest={80}
                        >
                          <Adw.Clamp
                            orientation={Gtk.Orientation.HORIZONTAL}
                            maximumSize={120}
                          >
                            <Gtk.Picture
                              class="picture"
                              contentFit={Gtk.ContentFit.COVER}
                              file={Gio.file_new_for_path(
                                `${HORIZONTAL_PATH}/${wallpaper}`,
                              )}
                            />
                          </Adw.Clamp>
                        </Adw.Clamp>
                      </button>
                    ))}
                  </Gtk.Box>
                ))}
              </Gtk.Box>
            )}
          </With>
        </box>
      </box>
    </CustomWindow>
  )
}
