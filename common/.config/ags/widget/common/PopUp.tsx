import { createState } from "ags"
import { getWindowSettingsCssClasses } from "../../utils/mainBar"
import { Gtk } from "ags/gtk4"

export interface PopUpProps {
  children: JSX.Element | Array<JSX.Element>
  cssClass: string
  autohide?: boolean
}

export default function PopUp({
  children,
  cssClass,
  autohide = true,
}: PopUpProps) {
  const [isPopoverOpen, setIsPopoverOpen] = createState(false)
  const classes = `window ${getWindowSettingsCssClasses()} ${cssClass}`
  return (
    <popover
      autohide={autohide}
      has_arrow={false}
      cascade_popdown
      onNotifyVisible={(p) => setIsPopoverOpen(p.visible)}
    >
      <revealer
        transitionDuration={300}
        transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
        revealChild={isPopoverOpen}
      >
        <box class={classes}>{children}</box>
      </revealer>
    </popover>
  )
}
