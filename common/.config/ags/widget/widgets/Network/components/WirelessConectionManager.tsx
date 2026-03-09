import AstalNetwork from "gi://AstalNetwork"
import { createBinding, createComputed, createState, With } from "ags"
import { Gtk } from "ags/gtk4"
import { AccessPointButton } from "./AccessPointButton"

const [wifiConnections, wifiConnectionsSetter] = createState<string[]>([])

export const WirelessConectionManager = ({
  network = AstalNetwork.get_default(),
}: {
  network?: AstalNetwork.Network
}) => {
  return (
    <box>
      <box class="connection-manager" orientation={Gtk.Orientation.VERTICAL}>
        <box class="title" hexpand>
          <label halign={Gtk.Align.CENTER} label="Availabe Networks" hexpand />
        </box>
        <box>
          <box>
            <With value={createBinding(network.wifi, "scanning")}>
              {(scanning) => {
                if (scanning)
                  return (
                    <box>
                      <label
                        cssClasses={["rotate", "network-scan-label"]}
                        hexpand
                        halign={Gtk.Align.CENTER}
                        marginBottom={4}
                        label=""
                      />
                    </box>
                  )
                else {
                  const accessPoints = network.wifi.accessPoints
                  const accessPointsUi = accessPoints
                    .filter((value) => {
                      return (
                        value.ssid != null &&
                        wifiConnections.peek().find((connection) => {
                          return value.ssid === connection
                        }) == null
                      )
                    })
                    .sort((a, b) => {
                      if (a.strength > b.strength) {
                        return -1
                      } else {
                        return 1
                      }
                    })
                    .map((accessPoint, index) => {
                      if (index < 10)
                        return <AccessPointButton accessPoint={accessPoint} />
                      return <></>
                    })
                  return (
                    <box>
                      <box orientation={Gtk.Orientation.VERTICAL} spacing={5}>
                        {accessPointsUi}
                      </box>
                    </box>
                  )
                }
              }}
            </With>
          </box>
        </box>
      </box>
    </box>
  )
}
