#!/usr/bin/env bash
# Builds the Windows installer (whowolf-VERSION-windows-x64-setup.exe) from the
# Flutter Windows build with Inno Setup (tool/windows/whowolf.iss).
# Usage: tool/package_windows_setup.sh <version> <Release-dir> <out-setup.exe>
#
# Runs in Git Bash on Windows. Inno Setup is pinned to a version and a sha256
# below: the script downloads the installer from its GitHub release, checks
# it and installs it for the current user into a temporary directory, unless
# ISCC points to an ISCC.exe already.
set -euo pipefail

[[ $# -eq 3 ]] || { echo "usage: $0 <version> <Release-dir> <out-setup.exe>" >&2; exit 2; }
version=$1
release=$(cd "$2" && pwd)
mkdir -p "$(dirname "$3")"
out_dir=$(cd "$(dirname "$3")" && pwd)
out_name=$(basename "$3" .exe)
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
  { echo "error: version must look like 0.1.0, got: $version" >&2; exit 2; }
[[ -f $release/whowolf.exe && -d $release/data ]] ||
  { echo "error: $release is not the Flutter Windows build (flutter build windows first)" >&2; exit 1; }
command -v cygpath >/dev/null || { echo "error: run this in Git Bash on Windows" >&2; exit 1; }
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/.." && pwd)

# Raise both lines together.
inno_url=https://github.com/jrsoftware/issrc/releases/download/is-6_7_3/innosetup-6.7.3.exe
inno_sha256=9c73c3bae7ed48d44112a0f48e66742c00090bdb5bef71d9d3c056c66e97b732

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
# Git Bash would turn every argument that starts with / into a path.
export MSYS2_ARG_CONV_EXCL='*'

iscc=${ISCC:-}
if [[ -z $iscc ]]; then
  curl -fsSL --retry 3 -o "$work/innosetup.exe" "$inno_url"
  echo "$inno_sha256  $work/innosetup.exe" | sha256sum -c --quiet - ||
    { echo "error: the Inno Setup installer does not match its pinned sha256" >&2; exit 1; }
  "$work/innosetup.exe" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /CURRENTUSER \
    "/DIR=$(cygpath -w "$work/inno")"
  iscc="$work/inno/ISCC.exe"
fi
[[ -f $iscc ]] || { echo "error: ISCC.exe not found at $iscc" >&2; exit 1; }

"$iscc" /Q \
  "/DAppVersion=$version" \
  "/DSourceDir=$(cygpath -w "$release")" \
  "/DRepoRoot=$(cygpath -w "$root")" \
  "/O$(cygpath -w "$out_dir")" \
  "/F$out_name" \
  "$(cygpath -w "$here/windows/whowolf.iss")"
echo "built $out_dir/$out_name.exe"
