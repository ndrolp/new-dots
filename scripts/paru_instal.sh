#!/bin/bash
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
