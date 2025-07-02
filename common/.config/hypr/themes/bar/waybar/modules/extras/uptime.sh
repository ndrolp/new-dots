#!/bin/sh

uptime_raw=$(uptime -p)
uptime=""

for word in $uptime_raw; do
    uptime+="${word^} "
done

uptime_result="${uptime#* }"

echo "$uptime_result"
