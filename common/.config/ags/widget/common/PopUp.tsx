import { createState } from "ags"
import { getWindowSettingsCssClasses } from "../../utils/mainBar"

export interface PopUpProps {
  children: JSX.Element | Array<JSX.Element>
  cssClass: string
}

export default function PopUp({ children, cssClass }: PopUpProps) {
  const [isPopoverOpen, setIsPopoverOpen] = createState(false)
  const classes = `window ${getWindowSettingsCssClasses()} ${cssClass}`
  return (
    <popover onNotifyVisible={(p) => setIsPopoverOpen(p.visible)}>
      <revealer revealChild={isPopoverOpen}>
        <box class={classes}>{children}</box>
      </revealer>
    </popover>
  )
}
