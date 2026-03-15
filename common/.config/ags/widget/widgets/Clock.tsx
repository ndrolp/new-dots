import { createPoll } from "ags/time"

export default function Clock() {
  // const date = createPoll("", 1000, `bash -c "date +%H:%M"`)
  const date = createPoll("", 1000, () => {
    return new Date().toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    })
  })

  return (
    <box class="bar-icon clock" spacing={0}>
      <box>
        <label label={date} />
      </box>
    </box>
  )
}
