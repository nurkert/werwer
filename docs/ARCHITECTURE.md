# Architektur

## Grundidee: alles in Dart

App und Server sind in Dart geschrieben. Die **Spielregeln liegen in einem eigenen Paket** (`game_core`), das die App nutzt. Das Spiel läuft immer auf dem Gerät des Spielleiters (Host), der Server vermittelt nur. Regeln werden so nur einmal geschrieben und getestet.

## Monorepo-Struktur

```
whowolf/
├── app/                    Flutter-App (Android, iOS, Web, Windows, macOS, Linux)
├── packages/
│   └── game_core/          Reines Dart: Rollen, Phasen, Regeln, Zustandsmaschine, Tests
├── server/                 Relay-Server (Vermittlung) + Auslieferung der Web-App, keine Spiellogik
├── website/                GitHub-Pages-Seite + Doku/Wiki
├── docker-compose.yml      Self-Hosting mit einem Befehl
├── docs/                   Planungsdokumente
└── .github/workflows/      CI + automatische Release-Builds
```

Dart-Workspaces (`pub workspace`) verbinden die Pakete im Monorepo.

## Ausbaustufen: erst lokal, dann Server als Vermittlung

**Stufe 1 (jetzt): Lokal im gleichen WLAN, kein Server.**

- Ein Gerät erstellt den Raum und ist **Host**. Auf ihm läuft die autoritative Spiellogik mit einem kleinen WebSocket-Server im LAN (`dart:io`).
- Alle anderen Geräte (auch der Host-Spieler selbst) sind **Clients** und verbinden sich per WebSocket mit dem Host. Der Host-Spieler bekommt keine Sonderrechte beim Wissen: Auch seine eigene App sieht nur seine gefilterte Sicht.
- Beitritt per **QR-Code** (enthält IP + Port + Raumcode), später zusätzlich automatische Suche im Netz (mDNS/Bonjour).
- **Plattformen:** So viele wie möglich. Hosten können alle nativen Plattformen (Android, iOS, macOS, Windows, Linux). **Flutter Web kann nicht hosten** (Browser dürfen keinen Server öffnen), aber als Client beitreten. Dafür könnte der Host die Web-App selbst per HTTP ausliefern. Wie genau, wird entschieden, wenn es so weit ist.
- Plattform-Details nicht vergessen: iOS braucht die Berechtigung „Lokales Netzwerk“, Android/Desktop ggf. Firewall-Freigaben.

**Stufe 2 (später): Server als Vermittlung (Relay) – gemischtes Spiel.**

- **Das Spiel läuft weiterhin auf dem Host-Gerät des Spielleiters.** Der Host ist immer die einzige Autorität, egal wie die Spieler verbunden sind.
- Der Host baut eine **ausgehende Verbindung zum Server** auf (funktioniert hinter jedem Router/NAT). Spieler, die nicht im WLAN sind, verbinden sich mit dem Server, der ihre Nachrichten **nur durchreicht**.
- **Gemischt:** Spieler im WLAN hängen direkt am Host, Spieler von außen kommen über den Server. Für die Host-Logik ist das egal, es sind einfach zwei Transporte gleichzeitig.
- Der Server kennt **keine Spielregeln und keinen Spielzustand**. Er verwaltet nur Raumcodes und leitet weiter. Billig zu betreiben, leicht selbst zu hosten, keine Spieldaten auf dem Server.
- **Beitritt per QR-Code vom Spielleiter:** Der Code zeigt auf die Server-Webseite, z. B. `https://play.whowolf.app/r/ABCD`. Dort: **„Im Browser mitspielen“** (Flutter Web) oder **„App installieren“**. Wer die App schon hat, landet per Deep Link (Universal Links / App Links) direkt im Raum.
- **Scan in der App:** Die App hat einen eigenen QR-Scanner. Scannt man den Code dort (oder öffnet den Link per Kamera), erkennt die App den Raum und tritt **direkt** bei, ohne Umweg über die Webseite. Der QR-Code ist also ein Link für alle Fälle: Browser, App-Installation oder direkter Beitritt.
- Der Code kann zusätzlich die lokale Adresse des Hosts enthalten. Die App versucht dann zuerst die direkte WLAN-Verbindung und nimmt den Server nur, wenn das nicht klappt.
- **Ohne Internet** zeigt der QR-Code auf die lokale Adresse des Hosts, der die Web-App dann selbst im WLAN ausliefert.
- **Server-Wahl:** Unser offizieller Server ist voreingestellt. Ein eigener Server lässt sich in den Einstellungen eintragen. **Keine Server-Abfrage im Onboarding** (widerspricht dem Schnellstart).

**Stufe 3 (im Hinterkopf): Server als Spielleiter.**

- Optional kann der Server selbst Host sein (ein „kopfloser“ Spielleiter ohne Spieler). Das ist dieselbe Host-Logik, nur auf dem Server statt in der App. Nützlich z. B. für reine Online-Runden oder wenn kein Gerät der Spielleiter sein soll.
- Zunächst wird das **nicht gebaut**. Die Host-Logik muss aber so geschrieben sein, dass sie ohne Flutter auch auf dem Server läuft.

**Damit das ohne Umbau klappt (von Anfang an einhalten):**

- **Host-Logik ist reines Dart** (Räume, Spieler, Timer, Reconnect, Anwendung von `game_core`), ohne Flutter und ohne `dart:io`. Uhr und Zufall werden injiziert. Sie läuft in der App auf dem Host-Gerät.
- **Transport ist eine Schnittstelle.** LAN-WebSocket, Relay über den Server und ein In-Memory-Transport für Tests sind austauschbare Implementierungen. Der Host kann **mehrere Transporte gleichzeitig** bedienen.
- **Ein Protokoll für alles:** Dieselben JSON-Nachrichten (Absichten rein, gefilterte Sichten + Ereignisse raus), egal ob lokal oder über Server. Das Protokoll hat eine Versionsnummer.
- Die App kennt nur „eine Verbindung zu einem Host“, nicht, wo dieser Host läuft.
- **Spieler sind über eine Sitzung identifiziert, nicht über die Verbindung.** Jeder bekommt beim Beitritt ein Sitzungstoken (lokal gespeichert). Damit kommt er nach Abbruch, Absturz oder Netzwechsel mit genau seinem Status zurück.
- **Spieler können jederzeit dazukommen** (Lobby und laufendes Spiel). Das Modell darf das nicht ausschließen.
- **Der Host speichert den Spielstand laufend** (Zustand ist serialisierbar), damit er nach einem Absturz weitermachen kann. Das Host-Gerät bleibt während des Spiels wach.
- **Medien werden vom Host gesteuert:** Der Host schickt „spiele Sound X um Zeitpunkt T“ an alle Geräte, damit Erzähler und Soundscape synchron laufen.

## Komponenten

### `packages/game_core`

- Reines Dart, keine Flutter- oder Netzwerk-Abhängigkeit.
- Enthält den Spielzustand, Rollen, Phasen und Aktionen als **Zustandsmaschine**:
  `zustand + aktion → neuer zustand + ereignisse`.
- Deterministisch und vollständig durch Unit-Tests abgedeckt.
- Erzeugt **pro Spieler gefilterte Sichten** auf den Zustand, sodass niemand mehr sieht, als er darf.

### `server/`

- Dart-Server (z. B. `shelf` + `shelf_web_socket`), kommt erst in Stufe 2.
- **Relay, nicht autoritativ:** Vergibt Raumcodes, verbindet Spieler mit dem passenden Host und reicht Nachrichten durch. Kennt keine Spielregeln und sieht keinen Spielzustand (die Nachrichten sind schon pro Spieler gefiltert).
- Liefert die **Flutter-Web-App** und die Beitrittsseite (`/r/<raumcode>`) aus, inkl. Download-Links und Deep Links.
- Zustand nur **im Speicher** (offene Räume/Verbindungen).
- Als **Docker-Image** verfügbar.

### `app/`

- Flutter, eine Codebasis für alle Plattformen.
- **Flutter Web** für den Beitritt per QR-Code ohne Installation.
- Server-Adresse in den Einstellungen änderbar: offizieller Server (Standard) oder eigener Server. Nicht im Onboarding abfragen.
- Erzähler: Sprachausgabe (TTS), später eigene Sprachaufnahmen, Musik, Sounds.

### `website/`

- Statische Seite auf GitHub Pages, im Look der App.
- Download-Seite für alle Betriebssysteme (Links zu GitHub Releases + App Store/Play Store).
- Doku/Wiki im Repo, z. B. mit **Astro + Starlight**. Damit ist sie versioniert und Teil von Pull Requests (statt GitHub-Wiki).
- Später eventuell die Flutter-Web-App unter derselben Domain.

## Netzwerk

- Verbindung über **WebSockets**, Nachrichten als JSON (später eventuell ein Binärformat).
- Client → Host: **Absichten** (`join`, `chooseTarget`, `vote`, …).
- Host → Client: **gefilterte Zustandsupdates** und Ereignisse.
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
