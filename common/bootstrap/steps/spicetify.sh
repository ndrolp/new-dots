#!/usr/bin/env bash
# Installs spicetify and its marketplace into the installed Spotify. Opt-in with --spicetify.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh
sudo chmod a+wr /opt/spotify
sudo chmod a+wr /opt/spotify/Apps -R
spicetify backup apply
curl -fsSL https://raw.githubusercontent.com/spicetify/marketplace/main/resources/install.sh | sh
summary_add installed spicetify
