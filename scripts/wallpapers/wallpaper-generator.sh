#!/usr/bin/env bash
#set -euo pipefail
shopt -s nullglob

if [ $# -ne 1 ]; then
    echo "Usage: $0 <wallpaper-folder>"
    exit 1
fi

BASE_DIR="$(realpath "$1")"
HORIZONTAL="$BASE_DIR/Horizontal"
VERTICAL="$BASE_DIR/Vertical"
PARENT_DIR="$(dirname "$BASE_DIR")"

if [[ ! -d "$HORIZONTAL" || ! -d "$VERTICAL" ]]; then
    echo "Error: folder must contain Horizontal/ and Vertical/"
    exit 1
fi

declare -A THEME_COMMANDS=(
    ["catppuccin"]="lutgen apply -p catppuccin-latte -L 0.65"
    ["gruvboxdark"]="lutgen apply -p gruvbox-light-hard -L 0.65"
    ["nord"]="lutgen apply -p nord-light"
    ["tokyonight"]="lutgen apply -p tokyo-night-dark"
)

TOTAL_IMAGES=0
CURRENT=0

# Count total images first
for dir in "$HORIZONTAL" "$VERTICAL"; do
    for img in "$dir"/*.{png,jpg,jpeg}; do
        [ -e "$img" ] || continue
        ((TOTAL_IMAGES++))
    done
done

# Multiply by number of themes
TOTAL_IMAGES=$((TOTAL_IMAGES * ${#THEME_COMMANDS[@]}))

draw_progress() {
    local percent=$((CURRENT * 100 / TOTAL_IMAGES))
    local width=40
    local filled=$((percent * width / 100))
    local empty=$((width - filled))

    printf "\r["
    printf "%0.s#" $(seq 1 $filled)
    printf "%0.s-" $(seq 1 $empty)
    printf "] %3d%% (%d/%d)" "$percent" "$CURRENT" "$TOTAL_IMAGES"
}

cleanup_themes() {
    echo "Cleaning old theme folders..."

    for theme in "${!THEME_COMMANDS[@]}"; do
        theme_dir="$PARENT_DIR/$theme"

        if [[ -d "$theme_dir" ]]; then
            rm -rf "$theme_dir"
        fi
    done
}

generate_images() {
    local src="$1"
    local dst="$2"
    local command="$3"

    mkdir -p "$dst"

    for img in "$src"/*.{png,jpg,jpeg}; do
        [ -e "$img" ] || continue

        filename=$(basename "$img")

        # Silence command output
        eval "$command -P \"$img\" -o \"$dst/$filename\"" > /dev/null 2>&1

        ((CURRENT++))
        draw_progress
    done
}

generate_theme() {
    local theme="$1"
    local command="${THEME_COMMANDS[$theme]}"
    local theme_dir="$PARENT_DIR/$theme"

    echo
    echo "Generating theme: $theme"

    generate_images "$HORIZONTAL" "$theme_dir/Horizontal" "$command"
    generate_images "$VERTICAL" "$theme_dir/Vertical" "$command"
}

cleanup_themes

for theme in "${!THEME_COMMANDS[@]}"; do
    generate_theme "$theme"
done

echo
echo "Done."
