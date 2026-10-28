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
# A release that failed to come up here is not tried again; only a new
# digest on the tag is (see README, "When a release does not start").
if [ -f .failed-image ] && [ "$ref" = "$(cat .failed-image)" ]; then
  exit 0
fi

if ! docker run --rm "$COSIGN" verify \
  --certificate-identity-regexp "$IDENTITY" \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  "$ref" >/dev/null 2>&1; then
  echo "error: $ref is not signed by $REPO's release workflow; not deployed" >&2
  exit 1
fi

# Waits until the relay service's container passes its healthcheck. Fails
# when it turns unhealthy, stops, restarts or takes longer than
# WHOWOLF_HEALTH_TIMEOUT seconds. Asks by service name, so a custom
# container_name or network does not matter.
wait_healthy() {
  deadline=$(($(date +%s) + ${WHOWOLF_HEALTH_TIMEOUT:-120}))
  while :; do
    id=$(docker compose ps --all --quiet relay | head -n 1)
    if [ -n "$id" ]; then
      state=$(docker inspect --format \
        '{{.State.Status}} {{.RestartCount}} {{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
        "$id" 2>/dev/null || echo gone)
      case $state in
        "running 0 healthy") return 0 ;;
        "running 0 starting" | "created 0 "*) ;;
        "running 0 none") return 0 ;;
        *) echo "relay container: $state" >&2; return 1 ;;
      esac
    fi
    if [ "$(date +%s)" -ge "$deadline" ]; then
      echo "relay container: not healthy after ${WHOWOLF_HEALTH_TIMEOUT:-120}s" >&2
      return 1
    fi
    sleep 2
  done
}

deploy() {
  printf 'RELAY_IMAGE=%s\n' "$1" > .env.new && mv .env.new .env
  docker compose up -d --remove-orphans && wait_healthy
}

if deploy "$ref"; then
  rm -f .failed-image
  echo "deployed $ref"
  docker image prune --force >/dev/null 2>&1 || true
  exit 0
fi

if [ -z "$current" ] || [ "$current" = "$ref" ]; then
  echo "error: $ref did not start, and there is no earlier release to go back to" >&2
  exit 1
fi
# Remember the broken digest first, so the timer does not deploy it again,
# and keep every image (no prune) until the old one runs again.
printf '%s\n' "$ref" > .failed-image
if deploy "$current"; then
  echo "error: $ref did not start; rolled back from $ref to $current" >&2
else
  echo "error: $ref did not start, and rolling back to $current failed too" >&2
fi
exit 1
