# Architektur

## Grundidee: alles in Dart

Client und Server sind in Dart geschrieben. Die **Spielregeln liegen in einem eigenen Paket** (`game_core`), das App und Server gemeinsam nutzen. Regeln werden so nur einmal geschrieben und getestet.

## Monorepo-Struktur

```
lycan/
├── app/                    Flutter-App (Android, iOS, Web, Windows, macOS, Linux)
├── packages/
│   └── game_core/          Reines Dart: Rollen, Phasen, Regeln, Zustandsmaschine, Tests
├── server/                 Dart-Server mit WebSockets, verbindliche Spiellogik
├── website/                GitHub-Pages-Seite + Doku/Wiki
├── docker-compose.yml      Self-Hosting mit einem Befehl
├── docs/                   Planungsdokumente
└── .github/workflows/      CI + automatische Release-Builds
```

Dart-Workspaces (`pub workspace`) verbinden die Pakete im Monorepo.

## Komponenten

### `packages/game_core`

- Reines Dart, keine Flutter- oder Netzwerk-Abhängigkeit.
- Enthält den Spielzustand, Rollen, Phasen und Aktionen als **Zustandsmaschine**:
  `zustand + aktion → neuer zustand + ereignisse`.
- Deterministisch und vollständig durch Unit-Tests abgedeckt.
- Erzeugt **pro Spieler gefilterte Sichten** auf den Zustand, sodass niemand mehr sieht, als er darf.

### `server/`

- Dart-Server (z. B. `shelf` + `shelf_web_socket`).
- **Autoritativ:** Nur der Server kennt den vollständigen Spielzustand.
- Verwaltet Räume (Raumcode), Spieler, Timer und Reconnects.
- Zustand zunächst **im Speicher**. Persistenz kommt erst, wenn sie gebraucht wird.
- Als **Docker-Image** verfügbar.

### `app/`

- Flutter, eine Codebasis für alle Plattformen.
- **Flutter Web** für den Beitritt per QR-Code ohne Installation.
- Server-Adresse wählbar: offizieller Server (Standard) oder eigener Server.
- Erzähler: Sprachausgabe (TTS), später eigene Sprachaufnahmen, Musik, Sounds.

### `website/`

- Statische Seite auf GitHub Pages, im Look der App.
- Download-Seite für alle Betriebssysteme (Links zu GitHub Releases + App Store/Play Store).
- Doku/Wiki im Repo, z. B. mit **Astro + Starlight**. Damit ist sie versioniert und Teil von Pull Requests (statt GitHub-Wiki).
- Später eventuell die Flutter-Web-App unter derselben Domain.

## Netzwerk

- Verbindung über **WebSockets**, Nachrichten als JSON (später eventuell ein Binärformat).
- Client → Server: **Absichten** (`join`, `chooseTarget`, `vote`, …).
- Server → Client: **gefilterte Zustandsupdates** und Ereignisse.
- Reconnect über ein Sitzungstoken pro Spieler und Raum.

## Self-Hosting

```bash
docker compose up -d
```

- Ein Container für den Server, optional einer für die Web-App.
- Konfiguration über Umgebungsvariablen (Port, erlaubte Origins, …).
- Anleitung kommt ins Wiki.

## Releases (CI/CD)

GitHub Actions baut bei jedem Release-Tag:

| Plattform | Ausgabe | Verteilung |
|---|---|---|
| Android | APK / AAB | GitHub Releases + Google Play |
| iOS | IPA | **nur App Store** (kein Download von der Website möglich) |
| macOS | DMG (signiert + notarisiert) | GitHub Releases (+ ggf. Mac App Store) |
| Windows | MSIX / EXE | GitHub Releases (ohne Zertifikat zeigt Windows eine Warnung an) |
| Linux | AppImage / tar.gz / Flatpak | GitHub Releases |
| Web | statische Dateien | GitHub Pages / eigener Server |
| Server | Docker-Image | GitHub Container Registry (ghcr.io) |

## Hosting des offiziellen Servers

- Anfangs reicht ein kleiner VPS (ein paar Euro im Monat).
- Später: Monitoring, Rate-Limits, Raumgrenzen.
