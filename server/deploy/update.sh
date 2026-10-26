#!/bin/sh
# Keeps the relay on the newest signed release. Run by the systemd timer
# (whowolf-update.timer) every few minutes, and once by hand to start.
#
# It pulls the image tag, checks that the image was built and signed by this
# repository's release workflow (Sigstore keyless signature, verified with
# the official cosign image), and only then runs it, pinned to the digest it
# checked. Nothing on the server listens for updates: it asks.
set -eu

IMAGE=${WHOWOLF_IMAGE:-ghcr.io/nurkert/whowolf-relay:stable}
REPO=${WHOWOLF_REPO:-nurkert/whowolf}
COSIGN=ghcr.io/sigstore/cosign/cosign:v3.1.4
IDENTITY="^https://github\\.com/${REPO}/\\.github/workflows/prerelease\\.yml@refs/tags/v[0-9]+\\.[0-9]+\\.[0-9]+\$"

cd "$(dirname "$0")"
if [ ! -f domain.env ]; then
  echo "error: create domain.env with RELAY_DOMAIN=your.domain first" >&2
  exit 1
fi

docker pull --quiet "$IMAGE" >/dev/null
ref=$(docker image inspect --format '{{index .RepoDigests 0}}' "$IMAGE")
current=$(sed -n 's/^RELAY_IMAGE=//p' .env 2>/dev/null || true)
if [ "$ref" = "$current" ] && docker compose ps --status running --quiet relay | grep -q .; then
  exit 0
fi

if ! docker run --rm "$COSIGN" verify \
  --certificate-identity-regexp "$IDENTITY" \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  "$ref" >/dev/null 2>&1; then
  echo "error: $ref is not signed by $REPO's release workflow; not deployed" >&2
  exit 1
fi

printf 'RELAY_IMAGE=%s\n' "$ref" > .env.new && mv .env.new .env
docker compose up -d --remove-orphans
echo "deployed $ref"
docker image prune --force >/dev/null 2>&1 || true
