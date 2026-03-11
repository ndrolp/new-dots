#!/bin/bash

gsettings set org.gnome.desktop.interface gtk-theme "Gruvbox-Material-Dark"

mkdir -p ~/.config/gtk-4.0
echo -e "[Settings]\ngtk-theme-name=Gruvbox-Material-Dark" > ~/.config/gtk-4.0/settings.ini
