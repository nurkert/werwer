# Security Policy

Whowolf is designed to be secure by default: game secrets never leave the host unfiltered, every connection is end-to-end encrypted, and the app collects no personal data. The full threat model (German) lives in [`docs/SECURITY_DESIGN.md`](docs/SECURITY_DESIGN.md).

## Supported versions

Whowolf is in early development. Security fixes go into the latest release only.

## Reporting a vulnerability

Please **do not open a public issue** for security problems.

Report privately via GitHub: **Security → Report a vulnerability** on this repository (private vulnerability reporting). Please include:

- what is affected (app, protocol, website, release artifacts),
- steps to reproduce or a proof of concept,
- the impact you expect.

You will get an acknowledgement as soon as possible. We will keep you updated, agree on a disclosure date with you, and credit you in the release notes if you wish.

## Scope

In scope: the app, the game protocol and handshake, the host's network service, release builds and the CI pipeline, and the website.

Known and documented limitation: the host device knows the full game state, so a player running a self-modified host build can cheat. See the threat model for details.
