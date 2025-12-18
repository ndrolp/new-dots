#!/bin/bash
updates=$(checkupdates 2>/dev/null | wc -l)
aur=$(paru -Qu --aur 2>/dev/null | wc -l)
total=$((updates + aur))

(( total == 0 )) && exit 0
echo "   $total"
