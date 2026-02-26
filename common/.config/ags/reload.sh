#!/bin/bash
PATH="$HOME/.config/nvm/versions/node/v24.4.1/bin:$PATH"
export PATH
ags quit
sleep 0.5
ags run &
disown
