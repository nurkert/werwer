# Roadmap

> **Qualitätsanspruch:** Tooling nach dem Prinzip „It just works“ ([TOOLING.md](TOOLING.md)) und **Secure by Design** von Anfang an ([SECURITY_DESIGN.md](SECURITY_DESIGN.md)).

> **Leitprinzip:** So schnell wie möglich zu einem **MVP**, das sich am Tisch gut anfühlt und als **GitHub-Release mit Website** veröffentlicht wird. Der Server kommt ganz zum Schluss. Er wird aber von Anfang an mitgedacht, damit er sich später ohne Umbau anschließen lässt (siehe [unten](#von-anfang-an-mitdenken)).

Jeder Meilenstein hat ein **Ziel** und ein **Fertig-wenn**. Die konkreten Arbeitspakete stehen als Tasks in [`docs/tasks/`](tasks/).

---

## Was ins MVP 0.1 gehört und was nicht

| Im MVP 0.1 | Bewusst später |
|---|---|
| Lokal im WLAN, ein Handy ist Host | Server, Relay, gemischtes Spiel |
| Beitritt per QR-Scanner in der App, Raumcode/IP als Fallback | Beitritt im Browser ohne Installation, mDNS-Suche |
| Rollen: Dorfbewohner, Werwolf, Seherin | Hexe, Jäger, Amor, Beschützer, eigene Rollen |
| Tarnaufgaben für alle (Anti-Tell) | Menschlicher Erzähler |
| Sitzordnung + Tischkreis aus eigener Perspektive | Beitritt während der Partie |
| **Wolfsspur v1** mit Morgen-Gähnen | Eulenspur und weitere Spuren |
| Einfacher Erzähler: Text + Sprachausgabe | Eigene Stimmen, Musik, Stimmungen |
| Rejoin mit vollem Status | Story am Spielende, Geistermodus |
| Deutsch + Englisch | Weitere Sprachen |
| iPhone (TestFlight) und Mac zuerst, dazu Android, Windows, Linux als Download | App Store, Google Play |
| Minimales eigenes Logo, Icon und Farben | Rollen-Artwork, Animationen |

---

## Spur D – Design & Website (parallel zum MVP)

**Ziel:** Ein unverwechselbarer, wertiger Auftritt im Stil **Mondbühne** ([DESIGN.md](DESIGN.md)), zuerst auf der Website, dann in der App.

- [x] Stilrichtung festlegen: **Mondbühne** (Referenz `design/reference/mondbuehne.jpg`)
- [x] D1 – Stil-Bibel: Referenzblätter (Werwolf, Seherin, Dorfbewohner), Figuren für alle geplanten Rollen, CI-Schrift Lilita One
- [x] D2 – Bühne in freigestellten Ebenen erzeugen (Prospekt, Kulissen, Figuren, Vordergrund, Rahmen); Figuren in Teilen für Gelenk-Animation folgt mit der App
- [ ] D3 – Design-Tokens als eine Quelle für Website (CSS-Variablen) und App (Flutter-Theme)
- [x] D4 – Website v1 gebaut (Deploy-Workflow steht; live, sobald DNS/Pages eingerichtet sind) unter **whowolf.de**: Astro, statisch, Bühnen-Hero mit Parallaxe, „Bald verfügbar“, Idee, Wolfsspur, Open Source; Lighthouse 100, keine Tracker
- [x] D5 – Logo (Schriftzug) und Emblem im Mondbühnen-Stil; App-Icon-Varianten folgen mit der App
- [x] D4b – Website ausgebaut: Theaterzettel-Look mit Papierstruktur, Schäfchen-Zählen zum Ausprobieren, Besetzung mit allen Rollen, Docs-Wiki, Download-Seite aus Releases, Impressum/Datenschutz, Deutsch + Englisch (weitere Sprachen per Datei), SEO (hreflang, Sitemap, JSON-LD)
- [ ] D6 – App-Theme und Kernkomponenten (Rollenkarte, Tischkreis, Bühnen-Momente, Schäfchen-Zählen) für M3

## M0 – Fundament

**Ziel:** Das Repo ist bereit für die Entwicklung, und Entscheidungen, die man später nur schwer ändern kann, sind getroffen.

- [x] Vision, Name (**Whowolf**), Lizenz (Apache 2.0), Repo, [Marktanalyse](MARKET.md)
- [ ] Dart-Workspace + `packages/game_core` + strikte Lints (Task 001)
- [x] Tooling: `.flutter-version`, `tool/check.sh` (= CI), `tool/deploy_ios.sh`, Signier-Sperre `tool/check_no_personal_ids.sh`
- [ ] `tool/doctor.sh`
- [x] **Walking Skeleton:** Flutter-App (`app/`, Startbildschirm mit Logo und Versionsstempel) läuft auf iPhone und Mac; Pre-Release-Pipeline baut bei Tag `v0.0.X` iOS (Compile-Check), macOS, Android, Windows, Linux mit Prüfsummen und Provenance
- [ ] CI von Anfang an: GitHub Actions ruft `tool/check.sh` auf (Format, Analyse, Tests, Secret-Scan, `osv-scanner`); Actions auf Commit-SHA gepinnt, minimale `permissions`
- [ ] Repo absichern: Branch-Schutz für `main`, Secret Scanning + Push Protection, private Schwachstellenmeldung, Dependabot
- [ ] **Früh festlegen, später teuer:**
  - [x] App-ID / Bundle-Identifier: **`de.whowolf.app`** (lässt sich nach einem Store-Release nicht mehr ändern)
  - [x] Domain **`whowolf.de`** gesichert; QR-Link-Format siehe [unten](#von-anfang-an-mitdenken)
  - [ ] Versionierung: SemVer + `CHANGELOG.md`
- [ ] Namen „Whowolf“ offiziell prüfen: DPMA/EUIPO (TMview), Stores, Domain, GitHub-Organisation

**Fertig, wenn:** Ein leeres `game_core` mit grüner CI auf `main` liegt.

## M1 – Spielregeln (`game_core`)

**Ziel:** Eine komplette Partie läuft regelkonform und getestet durch, ohne UI und ohne Netzwerk.

- [ ] Datenmodell: Spieler, Rollen, Lager, Einstellungen, Spielzustand, **Sitzordnung**
- [ ] Zustandsmaschine: Lobby → Rollen verteilen → Nacht → Morgen → Tag → Abstimmung → … → Ende
- [ ] Rollen: Dorfbewohner, Werwolf, Seherin; Rollenvorschlag nach Spielerzahl
- [ ] Anti-Tell: Tarnaufgaben für alle ohne Nachtaktion
- [ ] Siegbedingungen, Gleichstände, Phasen-Timeout
- [ ] Ereignisse für den Erzähler (nur Daten, keine Texte), gefilterte Spieler-Sichten
- [ ] Zustand serialisierbar (JSON)
- [ ] Sicherheit: Test für **jeden** Spieler, dass seine Sicht keine fremden Geheimnisse enthält; ungültige Aktionen ändern nie den Zustand
- [ ] Tests: jede Regel, komplette Partien über die öffentliche API, kein Informationsleck in den Sichten

**Fertig, wenn:** Die Akzeptanzkriterien aus Task 001 erfüllt sind und der Zustand verlustfrei in JSON und zurück geht.

## M2 – Host & lokales Netzwerk

**Ziel:** Mehrere Geräte spielen über das WLAN eine Partie. Zum Testen reicht ein Kommandozeilen-Client, es braucht noch keine App.

- [ ] **Host-Logik** in reinem Dart (eigenes Paket, z. B. `packages/game_host`): Raum, Raumcode, Spieler-Sitzungen, Timer. Uhr und Zufall werden injiziert.
- [ ] **Protokoll:** versionierte JSON-Nachrichten (Absichten rein, gefilterte Sichten + Ereignisse raus), eigenes Paket `packages/protocol`
- [ ] **Transport-Schnittstelle** mit In-Memory-Transport für Tests und LAN-WebSocket-Transport (`dart:io`, nur im Plattform-Teil)
- [ ] **Rejoin** per Sitzungstoken mit vollem Status; der Host speichert den Spielstand laufend und kann nach einem Absturz weitermachen
- [ ] **Sicherheit** ([SECURITY_DESIGN.md](SECURITY_DESIGN.md)):
  - Ende-zu-Ende-Verschlüsselung per Noise-Handshake (Host-Schlüssel + Raumgeheimnis aus dem QR-Code), Bibliothek prüfen und auswählen
  - Identität nur aus der Sitzung, Rechteprüfung jeder Absicht
  - Limits: Nachrichtengröße, Verbindungen, Handshake-Zeit, Rate; strenges Parsen
  - Gleicher Nachrichtentakt + Padding in geheimen Phasen (kein Seitenkanal)
  - Fuzz-/Property-Tests für Parser und Protokoll
- [ ] Integrationstest: Host + mehrere Clients spielen über den In-Memory-Transport eine ganze Partie, inklusive Verbindungsabbruch und Rejoin

**Fertig, wenn:** Zwei Rechner im selben WLAN über den Kommandozeilen-Client eine Partie spielen können und ein abgebrochener Client mit seinem Status zurückkommt.

## M3 – App: spielbarer Prototyp

**Ziel:** Mit Freunden eine echte Runde spielen, mit der App auf jedem Handy.

- [ ] Flutter-App im Workspace, Mehrsprachigkeit (Deutsch/Englisch) von Anfang an
- [ ] Start: Name eingeben → „Raum erstellen“ oder „Beitreten“
- [ ] Beitreten: **QR-Scanner in der App** (strenge Link-Prüfung, nur private Adressen, vor dem Verbinden bestätigen), Fallback Raumcode + IP manuell mit Host-Bestätigung und Prüfbild
- [ ] Sitzungstoken im sicheren Speicher (Keychain/Keystore); Berechtigungen erst bei Bedarf; keine Geheimnisse in Logs
- [ ] Lobby: **Tischkreis aus der eigenen Perspektive**, Sitzordnung festlegen und korrigieren, Rollenvorschlag, Start
- [ ] Spielbildschirme: Rolle ansehen → Nacht (Aktion bzw. Tarnaufgabe) → Morgen → Tag (wer lebt, Bildschirm dimmen) → Abstimmung → Sieg
- [ ] Erzähler: Text auf allen Geräten, Sprachausgabe auf dem Host-Gerät
- [ ] Bildschirm bleibt an (Wakelock), sauberes Reconnect nach Sperren oder Netzwechsel
- [ ] **Netzwerk-Fallstricke abfangen** und Hilfe anzeigen:
  - iOS-Berechtigung „Lokales Netzwerk“
  - Firewall-Freigabe auf dem Desktop
  - Gäste-WLAN mit Client-Isolation, Ausweg: Hotspot des Host-Handys
- [ ] Läuft auf iPhone und Mac (Hauptplattformen, dort wird getestet), Android (im Emulator auf dem Mac), Windows und Linux (CI-Builds, Linux-Test in einer VM)
- [ ] Deploy aufs eigene Handy per Skript (`tool/deploy_ios.sh`, Android per APK); Signierung nur lokal in git-ignorierten Dateien, nichts Persönliches im Repo

**Fertig, wenn:** Eine **erste Testrunde** mit 5+ Leuten ohne Wolfsspur von Anfang bis Ende funktioniert hat.

## M4 – Wolfsspur v1

**Ziel:** Das Alleinstellungsmerkmal ist spielbar ([NIGHT_SOUNDS.md](NIGHT_SOUNDS.md)).

- [ ] Uhrabgleich mit dem Host, synchrones Abspielen („Geräusch S auf Gerät D um Zeitpunkt T“)
- [ ] Spur-Logik in `game_core`: Wolfsspur nach der Spur-Regel, Atmosphäre-Geräusche, Überdecken, Morgen-Gähnen
- [ ] Audio in der App: Stummschalter auf iOS umgehen, Kopfhörer erkennen
- [ ] Einstellung aus / subtil / deutlich; Startwerte per **Simulation** mit einfachen Bots abschätzen
- [ ] Erste eigene bzw. lizenzfreie Geräusche (Herkunft dokumentiert)

**Fertig, wenn:** Die Wolfsspur in einer Testrunde zu Verdächtigungen am Tisch geführt hat und niemand sie als nervig empfand.

## M5 – Testen & Nachschärfen

**Ziel:** Aus „funktioniert“ wird „macht Spaß und ist zuverlässig“.

- [ ] 3–4 Testrunden mit verschiedenen Gruppen; Feedback in Issues festhalten
- [ ] Balance der Wolfsspur und der Rollenverteilung nachjustieren
- [ ] Bedienung vereinfachen: in unter 30 Sekunden vom Öffnen bis zur ersten Nacht
- [ ] Zuverlässigkeit: keine Spielabbrüche durch Verbindungsprobleme (häufigste Kritik bei der Konkurrenz)

**Fertig, wenn:** Testgruppen von sich aus nochmal spielen wollen.

## M6 – Release 0.1

**Ziel:** Whowolf ist öffentlich herunterladbar und verständlich präsentiert.

- [ ] Visuelle Identität aus Spur D in der App angekommen
- [ ] Release-Pipeline (GitHub Actions bei Tag `v*`): Android-APK (signiert), macOS, Windows, Linux → **GitHub-Release** mit Changelog, **SHA-256-Prüfsummen** und **Build-Provenance** (Artifact Attestations)
- [ ] Sicherheits-Check vor dem Release: Bedrohungsmodell durchgehen, `osv-scanner`, Secret-Scan
- [ ] iOS über **TestFlight** von Anfang an (Apple Developer Account vorhanden), macOS signiert und notarisiert
- [ ] **Website** (aus Spur D) um Downloads, Spielregeln und Mitmachen erweitern
- [ ] Datenschutz (keine Daten, kein Tracking) und Impressum für die Website prüfen
- [ ] `CONTRIBUTING.md`, Issue-Templates, README aktualisieren (`SECURITY.md` existiert bereits)
- [ ] Release-Hinweise: unsignierte Builds (Warnung unter macOS und Windows) erklären

**Fertig, wenn:** Jemand Fremdes über die Website die App findet, installiert und mit Freunden spielt.

---

## Nach dem MVP

Die Reihenfolge ist ein Vorschlag und wird nach dem Feedback zu 0.1 neu bewertet.

1. **Beitritt im Browser ohne Installation:** Der Host liefert die Flutter-Web-App im WLAN aus. Das ist der stärkste Wachstumshebel laut Marktanalyse.
2. **Mehr Spiel:**
   - Hexe, Jäger, Amor, Beschützer
   - Eulenspur und eigene Whowolf-Rollen (Fährtenleger, Lauscher, Stille Pfote)
   - Einstellungen
   - Beitritt während der Partie
   - menschlicher Erzähler, Story am Ende, Geistermodus
   - mDNS-Suche
3. **Design & Atmosphäre:** Rollen-Artwork, Stimmen, Musik, Stimmungen, Animationen.
4. **Stores:** Google Play (25 $ einmalig) und App Store, Datenschutzerklärung, Store-Einträge.
5. **Server (ganz zum Schluss):**
   - Relay-Server (`server/`) ohne Spiellogik
   - gemischtes Spiel
   - Beitrittsseite `whowolf.de/join` mit Deep Links
   - eigener Server in den Einstellungen
   - Docker-Image (ghcr.io) und offizieller Server auf eigenem VPS unter Subdomain von whowolf.de (Arbeitsname `game.whowolf.de`), mit genau diesem Container
   - optional: Server als Spielleiter

---

## Von Anfang an mitdenken

Damit der Server später ohne viel Arbeit andockt. Nichts davon wird für das MVP extra gebaut, es ist nur die Art, **wie** wir bauen:

- **Host-Logik in reinem Dart**, ohne Flutter und ohne `dart:io`. Uhr und Zufall werden injiziert. So läuft sie später unverändert auch auf einem Server.
- **Transport hinter einer Schnittstelle**, und der Host kann mehrere gleichzeitig bedienen. Das Relay ist dann nur ein weiterer Transport.
- **Ein versioniertes Protokoll** für lokal und Server. Die Pakete `protocol` und `game_host` sind schon so geschnitten, dass ein `server/` sie einfach importiert.
- **Spieler über Sitzungstoken identifizieren**, nicht über die Verbindung.
- **Spielzustand serialisierbar.**
- **Der QR-Code ist von Anfang an ein Link** auf eine Domain, die wir kontrollieren, z. B. `https://whowolf.de/join?room=ABCD&lan=192.168.0.5:4040`:
  - Im MVP liest nur die App den `lan`-Teil.
  - Später kommt die Server-Adresse dazu, und dieselbe URL wird zur Beitrittsseite im Browser.
  - Alte Apps verstehen neue Codes weiterhin.
- Die App kennt nur „eine Verbindung zu einem Host“, nicht, wo er läuft.
