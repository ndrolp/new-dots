import { Gtk } from "ags/gtk4"
import AstalHyprland from "gi://AstalHyprland"
import CustomWindow from "../../common/Window"
import Logger from "../../../utils/logger"
import { execAsync } from "ags/process"
import WallpapersBox from "./components/WallpapersBox"
import { getMonitorDirection } from "./lib/layout"
import { createComputed, createState, With } from "ags"
import { WINDOWS_NAMESPACES } from "../../windows"

export function WallpaperPickerContent() {
  const hypr = AstalHyprland.get_default()
  const Log = Logger.getInstance()
  const [horizontalWallpapers, setHorizontalWallPapers] = createState(
    [] as string[],
  )
  const [verticalWallpapers, setVericalWallppapers] = createState(
    [] as string[],
  )
  const [activeDisplay, setActiveDisplay] = createState(hypr.monitors[0])

  //TODO: Move the locations to a settings
  const HORIZONTAL_PATH = "/home/ndrolp/Pictures/Wallpapers/Current/Horizontal"
  const VERTICAL_PATH = "/home/ndrolp/Pictures/Wallpapers/Current/Vertical"

  const VERTICAL_THUMBNAILS =
    "/home/ndrolp/Pictures/Wallpapers Thumbnails/Vertical/"
  const HORIZONTAL_TUMBNAILS =
    "/home/ndrolp/Pictures/Wallpapers Thumbnails/Horizontal/"

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
      setVericalWallppapers(array)
    })
    .catch((error) => {
      Log.error(error)
    })

  const boxesData = createComputed(() => {
    const verticalBackgrounds = verticalWallpapers()
    const horizontalBackgrounds = horizontalWallpapers()
    return {
      verticalBackgrounds,
      horizontalBackgrounds,
    }
  })
  const horizontalReveal = createComputed(() => {
    return getMonitorDirection(activeDisplay().transform) === "horizontal"
  })
  const verticalReveal = createComputed(() => {
    return getMonitorDirection(activeDisplay().transform) === "vertical"
  })

  return (
    <box class="wallpaper-picker" spacing={10}>
        <box orientation={Gtk.Orientation.VERTICAL} spacing={10}>
          <box>
            <box class="monitor-selector" spacing={5}>
              {hypr.monitors.map((monitor) => {
                return (
                  <button
                    class={"monitor-button"}
                    onClicked={() => setActiveDisplay(monitor)}
                  >
                    <box spacing={0}>
                      <label label={monitor.name} />
                      <label label={": "} />
                      <label label={monitor.model} />
                    </box>
                  </button>
                )
              })}
            </box>
          </box>
          <box>
            <box>
              <With value={boxesData}>
                {(data) => {
                  return (
                    <box hexpand>
                      {hypr.monitors.map((monitor) => {
                        const direction = getMonitorDirection(monitor.transform)
                        return (
                          <box>
                            <revealer
                              transitionType={
                                direction === "vertical"
                                  ? Gtk.RevealerTransitionType.SLIDE_LEFT
                                  : Gtk.RevealerTransitionType.SLIDE_RIGHT
                              }
                              revealChild={
                                direction === "vertical"
                                  ? verticalReveal
                                  : horizontalReveal
                              }
                            >
                              <WallpapersBox
                                wallpapers={
                                  direction === "vertical"
                                    ? data.verticalBackgrounds
                                    : data.horizontalBackgrounds
                                }
                                monitorName={monitor.name}
                                path={
                                  direction === "vertical"
                                    ? VERTICAL_PATH
                                    : HORIZONTAL_PATH
                                }
                                thumbnailPath={
                                  direction === "vertical"
                                    ? VERTICAL_THUMBNAILS
                                    : HORIZONTAL_TUMBNAILS
                                }
                                direction={direction}
                              />
                            </revealer>
                          </box>
                        )
                      })}
                    </box>
                  )
                }}
              </With>
            </box>
          </box>
        </box>
    </box>
  )
}

export default function WallpaperPicker() {
  return (
    <CustomWindow
      visible={false}
      css="wallpaper-picker"
      position={Gtk.Align.CENTER}
      name={WINDOWS_NAMESPACES.wallpaper}
      namespace={WINDOWS_NAMESPACES.wallpaper}
    >
      <WallpaperPickerContent />
    </CustomWindow>
  )
}
