import Quickshell
import Quickshell.Hyprland._Ipc
import QtQml

import "components"

ShellRoot {
  Component.onCompleted: {
    Hyprland.refreshMonitors()
    Hyprland.refreshWorkspaces()
    Hyprland.refreshToplevels()
  }

  Variants {
    model: Quickshell.screens

    delegate: Bar {}
  }
}
