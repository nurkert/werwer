#!/bin/sh
# Tests server/deploy/update.sh against a real Docker: a release that crashes
# on start is rolled back to the running one, the script exits non-zero, and
# the next run skips the broken digest. Needs docker and the relay image
# (docker pull ghcr.io/nurkert/whowolf-relay:stable). Not part of check.sh.
#
# The signature check and the registry are faked by a `docker` wrapper on
# PATH (update.sh itself is unchanged): `pull` does nothing, `cosign verify`
# passes, and a locally built image's ID stands in for its registry digest.
set -eu
cd "$(dirname "$0")/.."
GOOD=${GOOD_IMAGE:-ghcr.io/nurkert/whowolf-relay:stable}
BAD=whowolf-relay:broken-test
REAL_DOCKER=$(command -v docker)
docker image inspect "$GOOD" >/dev/null 2>&1 ||
  { echo "error: pull $GOOD first" >&2; exit 1; }

work=$(mktemp -d)
cleanup() {
  (cd "$work/deploy" && "$REAL_DOCKER" compose down --remove-orphans >/dev/null 2>&1) || true
  "$REAL_DOCKER" image rm "$BAD" >/dev/null 2>&1 || true
  rm -rf "$work"
}
trap cleanup EXIT

# A copy of the deploy folder like a self-hoster's: no Caddy, its own
# project name, container name and network.
mkdir -p "$work/deploy" "$work/bin"
cp server/deploy/update.sh "$work/deploy/"
echo "RELAY_DOMAIN=localhost" > "$work/deploy/domain.env"
cat > "$work/deploy/docker-compose.yml" <<'YML'
name: whowolf-rollback-test
services:
  relay:
    image: ${RELAY_IMAGE:?}
    container_name: custom-relay-name-test
    restart: unless-stopped
    env_file: [domain.env]
    healthcheck:
      test: ["CMD", "/app/whowolf-relay", "healthcheck"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 30s
      start_interval: 2s
    networks: [elsewhere]
networks:
  elsewhere: {}
YML

cat > "$work/bin/docker" <<WRAP
#!/bin/sh
case "\$1 \${2:-} \${3:-}" in
  "pull "*) exit 0 ;;
  "run --rm "*) [ "\${4:-}" = verify ] && exit 0 ;;
  "image inspect --format")
    case "\$4" in *RepoDigests*)
      d=\$("$REAL_DOCKER" image inspect --format '{{index .RepoDigests 0}}' "\$5" 2>/dev/null) ||
        d=\$("$REAL_DOCKER" image inspect --format '{{.Id}}' "\$5")
      echo "\$d"; exit 0 ;;
    esac ;;
esac
exec "$REAL_DOCKER" "\$@"
WRAP
chmod +x "$work/bin/docker"

# The broken release: the same binary, but only its healthcheck runs,
# which finds no relay and exits 1 at once.
printf 'FROM %s\nENTRYPOINT ["/app/whowolf-relay", "healthcheck"]\n' "$GOOD" |
  docker build --quiet -t "$BAD" - >/dev/null 2>&1

update() { # <image> -> exit code of update.sh, output in $work/out
  PATH="$work/bin:$PATH" WHOWOLF_IMAGE=$1 WHOWOLF_HEALTH_TIMEOUT=60 \
    "$work/deploy/update.sh" > "$work/out" 2>&1
}
fail() { echo "error: update.sh: $1" >&2; cat "$work/out" >&2; exit 1; }
health() {
  id=$(cd "$work/deploy" && "$REAL_DOCKER" compose ps --all --quiet relay)
  "$REAL_DOCKER" inspect --format '{{.State.Health.Status}}' "$id"
}
pinned() { sed -n 's/^RELAY_IMAGE=//p' "$work/deploy/.env"; }

echo "▶ first install of a good release"
update "$GOOD" || fail "a good release was not deployed"
grep -q '^deployed ' "$work/out" || fail "no 'deployed' line"
[ "$(health)" = healthy ] || fail "good release not healthy"
old=$(pinned)

echo "▶ a release that crashes on start"
if update "$BAD"; then fail "a broken release exited 0"; fi
grep -q "rolled back from .* to $old" "$work/out" || fail "no rollback message"
[ "$(pinned)" = "$old" ] || fail ".env does not name the old release"
[ "$(health)" = healthy ] || fail "old release not healthy after the rollback"
[ -s "$work/deploy/.failed-image" ] || fail "broken digest not remembered"

echo "▶ the next run skips the broken digest"
update "$BAD" || fail "the remembered broken digest was not skipped"
[ ! -s "$work/out" ] || fail "skipping printed something"
[ "$(pinned)" = "$old" ] || fail "the broken release was deployed again"

echo "▶ a first install that fails has nothing to go back to"
(cd "$work/deploy" && "$REAL_DOCKER" compose down >/dev/null 2>&1 && rm -f .env .failed-image)
if update "$BAD"; then fail "a broken first install exited 0"; fi
grep -q "no earlier release" "$work/out" || fail "no first-install message"

echo "✓ update.sh rolls back"
