# Roadmap

> Leitprinzip: Erst muss sich **eine Runde am Tisch gut anfühlen**, dann Design, Website und Stores.

## Phase 0 – Grundlagen

- [x] Vision und Idee festhalten
- [x] Name: **Whowolf** (ersetzt „Werwer“ und den Arbeitstitel „Lycan“)
- [x] Lizenz: **Apache 2.0**
- [x] Repo angelegt
- [ ] Namen „Whowolf“ offiziell prüfen: Markenregister (DPMA / EUIPO), App Store, Play Store, Domain
- [ ] Monorepo-Gerüst anlegen (`app/`, `packages/game_core/`, `server/`, Dart-Workspace)

## Phase 1 – Spielregeln (`game_core`)

- [ ] Datenmodell: Spieler, Rollen, Lager, Spielzustand
- [ ] Zustandsmaschine: Lobby → Rollen verteilen → Nacht → Morgen → Tag → Abstimmung → …
- [ ] Rollen: Dorfbewohner, Werwolf, Seherin
- [ ] Siegbedingungen
- [ ] Gefilterte Spieler-Sichten (jeder sieht nur, was er darf)
- [ ] Unit-Tests für alle Regeln

## Phase 2 – Spielbarer Prototyp (lokal im WLAN, ohne Server)

- [ ] Host-Logik als reines Dart: Räume, Raumcode, Timer, Reconnect (Transport austauschbar)
- [ ] Versioniertes JSON-Protokoll (Absichten rein, gefilterte Sichten + Ereignisse raus)
- [ ] LAN-Transport: Host-Gerät öffnet WebSocket-Server, Clients verbinden sich
- [ ] Flutter-App (alle Plattformen): Raum erstellen/beitreten, Rolle ansehen, Nachtaktion, Abstimmung
- [ ] Anti-Tell: Dummy-Aufgaben für alle in der Nacht
- [ ] Beitritt per QR-Code (IP + Port + Raumcode), später Suche per mDNS
- [ ] Beitritt im Browser (Flutter Web als Client, Auslieferung durch den Host klären)
- [ ] Einfacher Erzähler (Text + Sprachausgabe)
- [ ] **Mit Freunden testen** und Feedback sammeln

## Phase 3 – Mehr Spiel

- [ ] Weitere Rollen: Hexe, Jäger, Amor, Beschützer
- [ ] Eigene Whowolf-Rollen
- [ ] Spiel-Einstellungen (Timer, Rollen aufdecken, Gleichstand-Regel)
- [ ] Story/Zusammenfassung am Spielende
- [ ] Geistermodus für tote Spieler

## Phase 4 – Design & Atmosphäre

- [ ] Visuelle Identität: Logo, App-Icon, Farben, Typografie
- [ ] Rollen-Artwork (komplett eigene Grafiken)
- [ ] Erzähler: Stimmen, Musik, Sounds, Stimmungen
- [ ] Animationen und Übergänge

## Phase 5 – Open-Source-Infrastruktur

- [ ] Relay-Server (`server/`): Raumcodes, Weiterleitung zwischen Host und Spielern von außen, keine Spiellogik
- [ ] Gemischtes Spiel: Host bedient LAN- und Relay-Transport gleichzeitig
- [ ] Beitrittsseite `/r/<raumcode>`: im Browser mitspielen oder App installieren, Deep Links in die App, QR-Scanner in der App für direkten Beitritt (WLAN bevorzugt, sonst Server)
- [ ] Eigener Server in den App-Einstellungen eintragbar (offizieller Server voreingestellt)
- [ ] `docker-compose.yml` + Docker-Image für den Server
- [ ] GitHub Actions: Tests, Builds für alle Plattformen, Releases
- [ ] Website auf GitHub Pages im App-Style mit Downloads
- [ ] Wiki/Doku (Spielregeln, Rollen, Self-Hosting, Mitmachen)
- [ ] `CONTRIBUTING.md`, Issue-Templates, Code of Conduct

## Phase 6 – Stores

- [ ] Apple Developer Account (99 $/Jahr)
- [ ] Google Play Developer Account (25 $ einmalig) + Testphase mit Testern
- [ ] Datenschutzerklärung
- [ ] Store-Einträge: Screenshots, Texte, Icons
- [ ] Offiziellen Server betreiben (VPS)
- [ ] Veröffentlichung 🎉
