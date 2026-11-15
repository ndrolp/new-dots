#!/usr/bin/env bash
# Runs one scan for the Printers panel (see Scanners.js scanCommand).
# Usage: scan.sh <out> <scanimage command…>
# Makes <out>'s folder, then runs the command, whose stderr (progress and
# errors) passes through. scanimage 1.4 writes <out>.part and renames it to
# <out> when done, so <out> existing is what tells a saved scan:
#   0    saved
#   100  saved, but scanimage failed after (its stderr says why)
#   else not saved: <out>.part is removed and scanimage's status returned
# <out> itself is never deleted.
set -u

out="$1"
shift
mkdir -p -- "$(dirname -- "$out")" || exit
"$@"
status=$?
if [[ -e "$out" ]]; then
    ((status == 0)) && exit 0
    exit 100
fi
rm -f -- "$out.part"
((status == 0)) && exit 1
exit "$status"
