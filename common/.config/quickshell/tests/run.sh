#!/usr/bin/env sh
# Runs the bar profile model tests (QtTest via qmltestrunner), outside of qs.
# Usage: common/.config/quickshell/tests/run.sh [extra qmltestrunner args]
set -eu
dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# Fixtures are read with XMLHttpRequest from file:// URLs.
export QML_XHR_ALLOW_FILE_READ=1
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-offscreen}"
# Otherwise Qt may send test output to the journal instead of the terminal.
export QT_FORCE_STDERR_LOGGING=1
# /usr/bin/qmltestrunner is the Qt 5 build on Arch; Quickshell is Qt 6.
runner="${QMLTESTRUNNER:-/usr/lib/qt6/bin/qmltestrunner}"
exec "$runner" -input "$dir" "$@"
