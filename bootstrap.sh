#!/bin/sh
clear

# COLORS
# Text color
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
# Text styles
BOLD='\033[1m'
UNDERLINE='\033[4m'
# Reset
NC='\033[0m' # No Color

# VARIABLES
HOSTNAME=$(hostname -s)
HOST_DIR="host-${HOSTNAME}"
COMMON_DIR="common"

set -e

#Start script

NO_BOOTSTRAP=false

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --no-bootstrap)
            NO_BOOTSTRAP=true
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

if [ "$NO_BOOTSTRAP" = false ]; then
    echo -e "${GREEN}\n${BOLD}Starting Dotfiles!${NC}\n"
    ./common/bootstrap/install.sh
else
    echo -e "${GREEN}\n${BOLD}Starting Dotfiles Withaut bootsrap scripts${NC}\n"
fi

echo -e "${GREEN}\n${BOLD}Stowing Config Files!${NC}\n"

stow -v -t ~ "$COMMON_DIR"

if [ -d "$HOST_DIR" ]; then
  echo "Stowing host-specific dotfiles for $HOSTNAME..."
  stow -v -t ~ "$HOST_DIR"
else
  echo "No host-specific config for $HOSTNAME."
fi
