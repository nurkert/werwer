# Running the Whowolf relay

The relay lets players who are not in the same Wi-Fi (mobile data, another
place) join a host. It forwards end-to-end encrypted messages between the
host's phone and the players and nothing else: no game logic, no game state,
no message contents in logs. The game itself keeps running on the host's
phone. `play.whowolf.de` runs exactly this setup.

## What it needs

A small Linux server with Docker (Compose v2), a domain pointing at it, and
ports 80 and 443 free. One vCPU and 512 MB of RAM carry hundreds of tables:
the relay only copies bytes.

## Setup

```sh
sudo mkdir -p /opt/whowolf
sudo cp server/deploy/* /opt/whowolf/
cd /opt/whowolf
echo "RELAY_DOMAIN=play.example.org" | sudo tee domain.env
sudo ./update.sh                       # pulls, verifies, starts relay + Caddy
sudo cp whowolf-update.service whowolf-update.timer /etc/systemd/system/
sudo systemctl enable --now whowolf-update.timer
```

Then enter `wss://play.example.org` in the app's settings. Caddy fetches the
TLS certificate by itself.

## Updates without an open door

`update.sh` runs every five minutes from the systemd timer. It pulls the
`stable` tag from `ghcr.io/nurkert/whowolf-relay` and checks its keyless
Sigstore signature: only an image signed by this repository's release
workflow (`.github/workflows/prerelease.yml`, on a version tag) is accepted.
Then it runs that exact digest. A new release is live within minutes. The
server opens no webhook or other endpoint for this; it asks.

Forks set `WHOWOLF_IMAGE` and `WHOWOLF_REPO` in the service's environment.

## Limits

The relay protects itself and the machine:
- **Per connection:** a byte budget. A connection that sends too much at
  once is cut off before a large frame is complete, so no single message can
  fill the memory.
- **Per address:** at most a few rooms, connections and new connections per
  minute. Behind Caddy the address comes from `X-Forwarded-For`
  (`TRUST_PROXY=1`, safe because only Caddy can reach the relay).
- **Totals:** rooms, connections and players per room are capped.
- **Container:** read-only, no capabilities, no new privileges, 256 MB of
  memory and one CPU at most.

All limits are environment variables in `docker-compose.yml` (see
`server/bin/server.dart`).

## Already running a reverse proxy?

Drop the `caddy` service and publish the relay on the loopback interface
only, e.g. `ports: ["127.0.0.1:8080:8080"]`. Proxy WebSocket requests for
your domain to it, and keep `TRUST_PROXY=1` only if your proxy overwrites
`X-Forwarded-For` with the client's address.
