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

# INSTALL NVM
echo -e "${YELLOW}\nInstall NVM${NC}\n"

if [ -n "$NVM_DIR" ]; then
  mkdir -p "$NVM_DIR"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
else
  echo "NVM_DIR is not defined. Aborting."
fi




echo -e "${YELLOW}\nInstall ZSH Plugins${NC}\n"

# Set custom plugin path (in case ZSH_CUSTOM is not set)
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

# zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
  echo "zsh-autosuggestions already installed."
fi

# zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
else
  echo "zsh-syntax-highlighting already installed."
fi
