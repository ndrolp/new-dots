#!/usr/bin/env bash

BASE_DIR="$HOME/Pictures/Wallpapers/"
DEFAULT_DIR="$HOME/Pictures/Wallpapers/Default/"

BASE_DIR="$HOME/Pictures/Horizontal/"
DEFAULT_DIR="$HOME/Pictures/Horizontal/Default/"


declare -A THEME_COMMANDS=(
    ["catppuccin"]="lutgen apply -p catppuccin-latte -L 0.65"
    ["gruvboxdark"]="lutgen apply -p gruvbox-light-hard -L 0.65 "
)

cleanup_themes() {
    echo "Cleaning old theme folders..."
    for dir in "$BASE_DIR"/*/; do
        folder=$(basename "$dir")
        if [ "$folder" != "Default" ]; then
            rm -rf "$dir"
        fi
    done
}

generate_theme() {
    scheme="$1"
    command="${THEME_COMMANDS[$scheme]}"

    if [ -z "$command" ]; then
        echo "No command defined for theme: $scheme"
        return 1
    fi

    THEME_DIR="$BASE_DIR/$scheme"
    mkdir -p "$THEME_DIR"

    echo "Generating theme: $scheme"

    for img in "$DEFAULT_DIR"/*.{png,jpg,jpeg}; do
        [ -e "$img" ] || continue
        filename=$(basename "$img")

        $command \
            -P "$img" \
            -o "$THEME_DIR/$filename"
    done
}

cleanup_themes
for scheme in "${!THEME_COMMANDS[@]}"; do
    generate_theme "$scheme"
done

echo "Done."
