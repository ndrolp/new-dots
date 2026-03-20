import { createState } from "ags"
import { getWindowSettingsCssClasses } from "../../utils/mainBar"
import { Gtk } from "ags/gtk4"

export interface PopUpProps {
  children: JSX.Element | Array<JSX.Element>
  cssClass: string
}

export default function PopUp({ children, cssClass }: PopUpProps) {
  const [isPopoverOpen, setIsPopoverOpen] = createState(false)
  const classes = `window ${getWindowSettingsCssClasses()} ${cssClass}`
  return (
    <popover
      has_arrow={false}
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
