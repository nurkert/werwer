#!/usr/bin/env bash
# Signs Apple builds in CI with an App Store Connect API key: Xcode fetches
# cloud-managed certificates and profiles itself, so the repo holds no
# certificate, profile or team ID.
#
#   tool/apple_release.sh ios VERSION BUILD     archive and upload to TestFlight
#   tool/apple_release.sh macos VERSION BUILD   Developer ID app, notarized and
#                                               stapled, zipped into dist/
#
# Needs (GitHub secrets, see docs/TOOLING.md):
#   APPLE_TEAM_ID, ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8_BASE64
# The key needs the App Manager role (Developer ID needs Admin).
set -euo pipefail

target=${1:?usage: apple_release.sh ios|macos VERSION BUILD}
version=${2:?version missing}
build=${3:?build number missing}
for name in APPLE_TEAM_ID ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_P8_BASE64; do
  if [[ -z "${!name:-}" ]]; then
    echo "error: $name is not set; add it as a repository secret (docs/TOOLING.md)." >&2
    exit 1
  fi
done

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
key="$work/AuthKey_$ASC_KEY_ID.p8"
printf '%s' "$ASC_KEY_P8_BASE64" | base64 --decode > "$key"
auth=(-allowProvisioningUpdates
  -authenticationKeyPath "$key"
  -authenticationKeyID "$ASC_KEY_ID"
  -authenticationKeyIssuerID "$ASC_ISSUER_ID")

cd "$root/app"
# The team ID only ever lives in the git-ignored Signing.xcconfig.
platform_dir=$([[ $target == ios ]] && echo ios || echo macos)
printf 'DEVELOPMENT_TEAM = %s\nCODE_SIGN_STYLE = Automatic\n' "$APPLE_TEAM_ID" \
  > "$platform_dir/Flutter/Signing.xcconfig"

flags=(--release --build-name="$version" --build-number="$build"
  --dart-define=APP_VERSION="$version")
options="$work/ExportOptions.plist"

case "$target" in
  ios)
    flutter build ios "${flags[@]}" --no-codesign
    xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner \
      -configuration Release -destination 'generic/platform=iOS' \
      -archivePath "$work/Runner.xcarchive" archive "${auth[@]}"
    # Exporting with destination "upload" sends the build to App Store
    # Connect, where it appears in TestFlight after processing.
    cat > "$options" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>teamID</key><string>$APPLE_TEAM_ID</string>
  <key>signingStyle</key><string>automatic</string>
</dict></plist>
EOF
    xcodebuild -exportArchive -archivePath "$work/Runner.xcarchive" \
      -exportOptionsPlist "$options" -exportPath "$work/export" "${auth[@]}"
    echo "Uploaded $version ($build) to TestFlight."
    ;;
  macos)
    flutter build macos "${flags[@]}"
    xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
      -configuration Release -archivePath "$work/Whowolf.xcarchive" archive \
      "${auth[@]}"
    cat > "$options" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>developer-id</string>
  <key>teamID</key><string>$APPLE_TEAM_ID</string>
  <key>signingStyle</key><string>automatic</string>
</dict></plist>
EOF
    xcodebuild -exportArchive -archivePath "$work/Whowolf.xcarchive" \
      -exportOptionsPlist "$options" -exportPath "$work/export" "${auth[@]}"
    app="$work/export/Whowolf.app"
    zip="$root/dist/whowolf-$version-macos.zip"
    mkdir -p "$root/dist"
    ditto -c -k --keepParent "$app" "$zip"
    xcrun notarytool submit "$zip" --key "$key" --key-id "$ASC_KEY_ID" \
      --issuer "$ASC_ISSUER_ID" --wait
    xcrun stapler staple "$app"
    # Zip again so the download carries the stapled ticket (works offline).
    rm "$zip"
    ditto -c -k --keepParent "$app" "$zip"
    echo "Signed and notarized: $zip"
    ;;
  *)
    echo "error: unknown target '$target' (ios or macos)" >&2
    exit 1
    ;;
esac
