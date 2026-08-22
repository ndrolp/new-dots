#!/bin/bash
PATH="$HOME/.config/nvm/versions/node/v25.8.1/bin:$PATH"
export PATH
ags quit
killall qs
sleep 0.5
#ags run & disown
qs & disown

