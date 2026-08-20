import { createState } from "ags"
import { getWindowSettingsCssClasses } from "../../utils/mainBar"
import { Gtk } from "ags/gtk4"

export interface PopUpProps {
  children: JSX.Element | Array<JSX.Element>
  cssClass: string
  autohide?: boolean
  transitionDuration?: number
}

export default function PopUp({
  children,
  cssClass,
  autohide = true,
  transitionDuration = 300,
}: PopUpProps) {
  const [isPopoverOpen, setIsPopoverOpen] = createState(false)
  const classes = `popup ${getWindowSettingsCssClasses()} ${cssClass}`
  return (
    <popover
      autohide={autohide}
      has_arrow={false}
      cascade_popdown
      onNotifyVisible={(p) => setIsPopoverOpen(p.visible)}
    >
      <revealer
        transitionDuration={transitionDuration}
        transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
        revealChild={isPopoverOpen}
      >
        <box class={classes}>{children}</box>
      </revealer>
    </popover>
  )
}
