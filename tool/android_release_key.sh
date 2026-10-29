#!/usr/bin/env bash
# Creates Whowolf's Android release key ONCE, outside the repository, and
# prints what goes into the repository secrets (docs/TOOLING.md, "Android:
# fester Release-Schlüssel"). Every release is then signed with this key, so
# phones update in place instead of refusing a different signature.
#
# Keep the key and both passwords safe and backed up: without them no
# update can ever be installed over the existing app again.
#
# Usage: tool/android_release_key.sh [path/to/whowolf-release.jks]
set -euo pipefail

here="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:-$HOME/whowolf-release.jks}"
dir="$(cd "$(dirname "$out")" && pwd)"
out="$dir/$(basename "$out")"

case "$out" in
  "$here"/*)
    echo "error: $out is inside the repository; keys never go in here. Pick a path outside, e.g. ~/whowolf-release.jks" >&2
    exit 1 ;;
esac
if [[ -e "$out" ]]; then
  echo "error: $out already exists. The key is made once; reuse it (or move it away if you really mean to start over: every installed app then needs a reinstall)." >&2
  exit 1
fi
# A keytool that runs: on macOS /usr/bin/keytool is only a stub without a
# Java runtime, so fall back to the one inside Android Studio.
keytool=""
for candidate in "${JAVA_HOME:+$JAVA_HOME/bin/keytool}" keytool \
  "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"; do
  [[ -n "$candidate" ]] || continue
  if "$candidate" -help >/dev/null 2>&1; then keytool="$candidate"; break; fi
done
if [[ -z "$keytool" ]]; then
  echo "error: no working keytool; install a JDK (brew install openjdk) or Android Studio, or set JAVA_HOME" >&2
  exit 1
fi

alias_name="whowolf"
# PKCS12 keeps one password for store and key.
password="$(openssl rand -base64 32 | tr -d '/+=' | cut -c1-32)"

"$keytool" -genkeypair \
  -keystore "$out" -storetype PKCS12 \
  -alias "$alias_name" -keyalg RSA -keysize 4096 -validity 10950 \
  -storepass "$password" -keypass "$password" \
  -dname "CN=Whowolf, O=Whowolf" >/dev/null
chmod 600 "$out"

fingerprint="$("$keytool" -list -v -keystore "$out" -storepass "$password" -alias "$alias_name" \
  | awk -F': ' '/SHA256:/ {print $2; exit}')"

cat <<INFO

Created $out (valid 30 years). Back it up now, together with the password,
e.g. in your password manager. Lose either and updates are impossible.

Repository secrets (GitHub → Settings → Secrets and variables → Actions):

  ANDROID_KEYSTORE_BASE64   run:  base64 -i "$out" | pbcopy   then paste
  ANDROID_KEY_ALIAS         $alias_name
  ANDROID_KEY_PASSWORD      the password below (store and key share it)

Password (shown once, not stored anywhere by this script):

  $password

Certificate SHA-256 (public; for ANDROID_CERT_SHA256 on the relay, App Links):

  $fingerprint

INFO
