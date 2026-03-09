import { createPoll } from "ags/time"

export default function Clock() {
  const date = createPoll("", 1000, `bash -c "date +%H:%M"`)

  return (
    <box class="bar-icon clock" spacing={0}>
      <box>
        <label label={date} />
      </box>
    </box>
  )
}
