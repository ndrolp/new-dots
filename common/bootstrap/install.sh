#!/bin/sh

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

set -e

# Resolve the directory this script is in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the root of the repo (one level up from common/)
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Path to the package list
PKG_LIST="${ROOT_DIR}/packages/pacman.txt"

# Ensure the file exists
if [[ ! -f "$PKG_LIST" ]]; then
  echo -e "${RED} Package list not found: $PKG_LIST ${NC} \n"
  exit 1
fi

# Install packages with pacman
echo -e "${YELLOW}\nUpdate Pacman${NC}\n"
sudo pacman -Syu --noconfirm
echo -e "${YELLOW}\nInstall pacman packages${NC}\n"
sudo pacman -Sy --needed --noconfirm - < "$PKG_LIST"
rustup default stable

# INSTALL PARU

if command -v paru >/dev/null 2>&1; then
  echo -e "${YELLOW}✅ Paru is already installed.${NC}\n"
else
  echo -e "${YELLOW}🚀 Paru not found. Installing...${NC}\n"

  # Create a temporary directory
  TMP_DIR=$(mktemp -d)

  echo -e "${CYAN}Cloning paru into $TMP_DIR...${NC}\n"

  git clone https://aur.archlinux.org/paru.git "$TMP_DIR/paru"

  cd "$TMP_DIR/paru"

  echo -e "${CYAN}Building and installing paru...${NC}\n"
  makepkg -si --noconfirm

  echo -e "${BLUE}Cleaning up...${NC}\n"
  rm -rf "$TMP_DIR"

  echo "${GREEN}✅ paru installed successfully.${NC}\n"
fi

PKG_LIST="${ROOT_DIR}/packages/paru.txt"

# Ensure the file exists
if [[ ! -f "$PKG_LIST" ]]; then
  echo -e "${RED} Package list not found: $PKG_LIST ${NC} \n"
  exit 1
fi

echo -e "${YELLOW}\nInstall Paru packages${NC}\n"

paru -Sy --needed --noconfirm - < "$PKG_LIST"