import { createPoll } from "ags/time"

export default function Clock() {
  const date = createPoll("", 1000, `bash -c "date +%H:%M"`)

  return (
    <box class="clock">
      <label label={date} />
    </box>
  )
}
