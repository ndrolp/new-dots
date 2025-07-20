#!/bin/bash
songinfo=$(playerctl metadata --format '🎵    {{title}} - {{artist}}')

echo "$songinfo"
