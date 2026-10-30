#!/usr/bin/env bash
# Installs the Windows installer silently for the current user, checks that
# Whowolf landed with its data and an uninstaller, then uninstalls it and
# checks that it is gone. Runs in Git Bash on a Windows CI runner.
# Usage: tool/check_windows_setup.sh <setup.exe>
set -euo pipefail

[[ $# -eq 1 ]] || { echo "usage: $0 <setup.exe>" >&2; exit 2; }
setup=$1
[[ -f $setup ]] || { echo "error: $setup not found" >&2; exit 1; }
export MSYS2_ARG_CONV_EXCL='*'

dir=$(cygpath -u "$LOCALAPPDATA")/Programs/Whowolf
"$setup" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /CURRENTUSER /LOG="$(cygpath -w "$RUNNER_TEMP/setup.log")"
for file in whowolf.exe flutter_windows.dll data/flutter_assets/AssetManifest.bin; do
  [[ -f "$dir/$file" ]] || { echo "error: $dir/$file missing after install" >&2; exit 1; }
done
uninstaller=$(find "$dir" -maxdepth 1 -name 'unins*.exe' | head -n 1)
[[ -n $uninstaller ]] || { echo "error: no uninstaller in $dir" >&2; exit 1; }
echo "✓ installed to $dir"

"$uninstaller" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
# The uninstaller finishes in a copy of itself, so wait for the folder to go.
for _ in $(seq 1 60); do
  [[ -f "$dir/whowolf.exe" ]] || { echo "✓ uninstalled"; exit 0; }
  sleep 1
done
echo "error: whowolf.exe is still there after uninstalling" >&2
exit 1
