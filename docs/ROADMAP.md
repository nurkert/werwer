# Roadmap

> **Qualitätsanspruch:** Tooling nach dem Prinzip „It just works“ ([TOOLING.md](TOOLING.md)) und **Secure by Design** von Anfang an ([SECURITY_DESIGN.md](SECURITY_DESIGN.md)).

> **Leitprinzip:** So schnell wie möglich zu einem **MVP**, das sich am Tisch gut anfühlt und als **GitHub-Release mit Website** veröffentlicht wird. Der Server kommt ganz zum Schluss. Er wird aber von Anfang an mitgedacht, damit er sich später ohne Umbau anschließen lässt (siehe [unten](#von-anfang-an-mitdenken)).

Jeder Meilenstein hat ein **Ziel** und ein **Fertig-wenn**. Die konkreten Arbeitspakete stehen als Tasks in [`docs/tasks/`](tasks/).

---

## Was ins MVP 0.1 gehört und was nicht

| Im MVP 0.1 (bis 2026-11-01) | Bewusst später |
|---|---|
| Lokal im WLAN, ein Handy ist Host; Relay mit eigenem Server | Offizieller Server, gemischtes Spiel |
| Beitritt per Raumsuche (Bonjour) und QR-Code, Raumcode/IP als Fallback | Beitritt im Browser ohne Installation |
| Rollen: Dorfbewohner, Werwolf, Seherin, **Hexe, Jäger, Amor** | Beschützer, eigene Rollen, Beitritt während der Partie |
| Stufen Klassisch → Whowolf → Volle Bühne, jede eigene Funktion abschaltbar | Menschlicher Erzähler |
| Tarnaufgaben für alle (Schäfchen zählen) | Eulenspur und weitere Spuren |
| **Wolfsspur light:** Morgen-Gähnen + Atmosphäre | Volle Wolfsspur mit Uhrabgleich |
| **Fehlertolerant:** Pausenmodus, Wiederfinden, Aktionen gehen nie verloren | Host-Übernahme durch einen Spieler |
| Mondbühnen-Design in der App, Figuren als Pappmodell, gleich viele Frauen und Männer | Eigene Figuren (Editor + Teilen), Musik, Stimmungen |
| Einfacher Erzähler: Text + Sprachausgabe | Eigene Stimmen, Story am Spielende, Geistermodus |
| Deutsch + Englisch | Weitere Sprachen |
| iPhone und Mac zuerst, dazu Android, Windows, Linux als Download | App Store, Google Play |
| Zuverlässigkeit durch Chaos- und Simulationstests | Externer Krypto-Review (Pflicht vor den Stores) |


---

## Spur D – Design & Website (parallel zum MVP)

**Ziel:** Ein unverwechselbarer, wertiger Auftritt im Stil **Mondbühne** ([DESIGN.md](DESIGN.md)), zuerst auf der Website, dann in der App.

- [x] Stilrichtung festlegen: **Mondbühne** (Referenz `design/reference/mondbuehne.jpg`)
- [x] D1 – Stil-Bibel: Referenzblätter (Werwolf, Seherin, Dorfbewohner), Figuren für alle geplanten Rollen, CI-Schrift Lilita One
- [x] D2 – Bühne in freigestellten Ebenen erzeugen (Prospekt, Kulissen, Figuren, Vordergrund, Rahmen); Figuren in Teilen für Gelenk-Animation folgt mit der App
- [x] D3 – Design-Tokens als eine Quelle für Website (CSS-Variablen) und App (Flutter-Theme)
- [x] D4 – Website v1 gebaut (Deploy-Workflow steht; live, sobald DNS/Pages eingerichtet sind) unter **whowolf.de**: Astro, statisch, Bühnen-Hero mit Parallaxe, „Bald verfügbar“, Idee, Wolfsspur, Open Source; Lighthouse 100, keine Tracker
- [x] D5 – Logo (Schriftzug) und Emblem im Mondbühnen-Stil; App-Icon-Varianten folgen mit der App
- [x] D4b – Website ausgebaut: Theaterzettel-Look mit Papierstruktur, Schäfchen-Zählen zum Ausprobieren, Besetzung mit allen Rollen, Docs-Wiki, Download-Seite aus Releases, Impressum/Datenschutz, Deutsch + Englisch (weitere Sprachen per Datei), SEO (hreflang, Sitemap, JSON-LD)
- [x] D6 – App-Theme und Kernkomponenten (Rollenkarte, Tischkreis, Bühnen-Momente, Schäfchen-Zählen) für M3

> **Stand 2026-10-25:** Eine minimal spielbare Testversion steht: WLAN und Relay-Server (Docker Compose), QR-Beitritt, Rejoin nach Neustart; noch ohne Ende-zu-Ende-Verschlüsselung, ohne Tischkreis und ohne Host-Absturzsicherung. Siehe DECISIONS.md.

## M0 – Fundament

**Ziel:** Das Repo ist bereit für die Entwicklung, und Entscheidungen, die man später nur schwer ändern kann, sind getroffen.

- [x] Vision, Name (**Whowolf**), Lizenz (Apache 2.0), Repo, [Marktanalyse](MARKET.md)
- [x] Dart-Workspace + `packages/game_core` + strikte Lints (Task 001)
- [x] Tooling: `tool/check.sh` (= CI), `tool/deploy_ios.sh`, Signier-Sperre `tool/check_no_personal_ids.sh`
- [x] `tool/doctor.sh`
- [x] **Walking Skeleton:** Flutter-App (`app/`, Startbildschirm mit Logo und Versionsstempel) läuft auf iPhone und Mac; Pre-Release-Pipeline baut bei Tag `v0.0.X` iOS (Compile-Check), macOS, Android, Windows, Linux mit Prüfsummen und Provenance
- [x] CI von Anfang an: GitHub Actions ruft `tool/check.sh` auf (Format, Analyse, Tests, Secret-Scan, `osv-scanner`); Actions auf Commit-SHA gepinnt, minimale `permissions`
- [x] Repo absichern: Dependabot (`.github/dependabot.yml`), Secret-Scan in der CI. **Einmalig von Hand in den GitHub-Einstellungen** (geht nur mit Admin-Zugang): Branch-Schutz für `main`, Secret Scanning + Push Protection, private Schwachstellenmeldung – Klickliste in TOOLING.md
- [x] **Früh festlegen, später teuer:**
  - [x] App-ID / Bundle-Identifier: **`de.whowolf.app`** (lässt sich nach einem Store-Release nicht mehr ändern)
  - [x] Domain **`whowolf.de`** gesichert; QR-Link-Format siehe [unten](#von-anfang-an-mitdenken)
  - [x] Versionierung: SemVer + `CHANGELOG.md`
- [x] Namen „Whowolf“ prüfen: Stores, Domain, GitHub, Websuche erledigt (siehe LEGAL.md); **offizielle Registerrecherche DPMA/TMview durch den Eigentümer vor dem Store-Release**

**Fertig, wenn:** Ein leeres `game_core` mit grüner CI auf `main` liegt.

## M1 – Spielregeln (`game_core`)

**Ziel:** Eine komplette Partie läuft regelkonform und getestet durch, ohne UI und ohne Netzwerk.

- [x] Datenmodell: Spieler, Rollen, Lager, Einstellungen, Spielzustand, **Sitzordnung**
- [x] Zustandsmaschine: Lobby → Rollen verteilen → Nacht → Morgen → Tag → Abstimmung → … → Ende
- [x] Rollen: Dorfbewohner, Werwolf, Seherin; Rollenvorschlag nach Spielerzahl
- [x] Anti-Tell: Tarnaufgaben für alle ohne Nachtaktion
- [x] Siegbedingungen, Gleichstände, Phasen-Timeout
- [x] Ereignisse für den Erzähler (nur Daten, keine Texte), gefilterte Spieler-Sichten
- [x] Zustand serialisierbar (JSON)
- [x] Sicherheit: Test für **jeden** Spieler, dass seine Sicht keine fremden Geheimnisse enthält; ungültige Aktionen ändern nie den Zustand
- [x] Tests: jede Regel, komplette Partien über die öffentliche API, kein Informationsleck in den Sichten

**Fertig, wenn:** Die Akzeptanzkriterien aus Task 001 erfüllt sind und der Zustand verlustfrei in JSON und zurück geht.

## M2 – Host & lokales Netzwerk

**Ziel:** Mehrere Geräte spielen über das WLAN eine Partie. Zum Testen reicht ein Kommandozeilen-Client, es braucht noch keine App.

- [x] **Host-Logik** in reinem Dart (eigenes Paket, z. B. `packages/game_host`): Raum, Raumcode, Spieler-Sitzungen, Timer. Uhr und Zufall werden injiziert.
- [x] **Protokoll:** versionierte JSON-Nachrichten (Absichten rein, gefilterte Sichten + Ereignisse raus), eigenes Paket `packages/protocol`
- [x] **Transport-Schnittstelle** mit In-Memory-Transport für Tests und LAN-WebSocket-Transport (`dart:io`, nur im Plattform-Teil)
- [x] **Rejoin** per Sitzungstoken mit vollem Status; der Host speichert den Spielstand laufend und kann nach einem Absturz weitermachen
- [x] **Sicherheit** ([SECURITY_DESIGN.md](SECURITY_DESIGN.md)):
  - Ende-zu-Ende-Verschlüsselung aus libsodium-Bausteinen (Host-Schlüssel + Raumgeheimnis aus dem QR-Code; ohne QR Prüfbild mit Commitment)
  - Identität nur aus der Sitzung, Rechteprüfung jeder Absicht
  - Limits: Nachrichtengröße, Verbindungen, Handshake-Zeit, Rate; strenges Parsen
  - Gleicher Nachrichtentakt + Padding in geheimen Phasen (kein Seitenkanal)
  - Fuzz-/Property-Tests für Parser und Protokoll
- [x] Integrationstest: Host + mehrere Clients spielen über den In-Memory-Transport eine ganze Partie, inklusive Verbindungsabbruch und Rejoin

**Fertig, wenn:** Zwei Rechner im selben WLAN über den Kommandozeilen-Client eine Partie spielen können und ein abgebrochener Client mit seinem Status zurückkommt.

> Erreicht am 2026-10-26: Drei Kommandozeilen-Prozesse haben über die WLAN-Adresse verschlüsselt eine Partie bis zum Sieg gespielt; Abbruch und Rejoin mit Status deckt `packages/cli/test/cli_test.dart` ab. Ein Test mit zwei physischen Rechnern steht noch aus.

## M3 – App: spielbarer Prototyp

**Ziel:** Mit Freunden eine echte Runde spielen, mit der App auf jedem Handy.

- [x] Flutter-App im Workspace, Mehrsprachigkeit (Deutsch/Englisch) von Anfang an
- [x] Start: Name eingeben → „Raum erstellen“ oder „Beitreten“
- [x] Beitreten: **QR-Scanner in der App** (strenge Link-Prüfung, nur private Adressen, vor dem Verbinden bestätigen), Fallback Raumcode + IP manuell mit Host-Bestätigung und Prüfbild
- [x] Sitzungstoken im sicheren Speicher (Keychain/Keystore); Berechtigungen erst bei Bedarf; keine Geheimnisse in Logs
- [x] Lobby: **Tischkreis aus der eigenen Perspektive**, Sitzordnung festlegen und korrigieren, Rollenvorschlag, Start
- [x] Spielbildschirme: Rolle ansehen → Nacht (Aktion bzw. Tarnaufgabe) → Morgen → Tag (wer lebt, Bildschirm dimmen) → Abstimmung → Sieg
- [x] Erzähler: Text auf allen Geräten, Sprachausgabe auf dem Host-Gerät
- [x] Bildschirm bleibt an (Wakelock), sauberes Reconnect nach Sperren oder Netzwechsel
- [x] **Netzwerk-Fallstricke abfangen** und Hilfe anzeigen:
  - iOS-Berechtigung „Lokales Netzwerk“
  - Firewall-Freigabe auf dem Desktop
  - Gäste-WLAN mit Client-Isolation, Ausweg: Hotspot des Host-Handys
- [ ] Läuft auf iPhone und Mac (Hauptplattformen, dort wird getestet), Android (im Emulator auf dem Mac), Windows und Linux (CI-Builds, Linux-Test in einer VM)
- [x] Deploy aufs eigene Handy per Skript (`tool/deploy_ios.sh`, Android per APK); Signierung nur lokal in git-ignorierten Dateien, nichts Persönliches im Repo

- [x] **Beitritt ohne Technik:** Räume im WLAN werden automatisch gefunden (mDNS/Bonjour), QR-Code als zweiter Weg; IP, Port und Codes nur klein unter „Details“
- [x] **Website-Startbild aus Pappebenen:** auch der Hintergrund (Himmel, Mond, Berge, Hügel, Wiese) als gestaffelte Pappstücke mit eigener Parallaxe statt einer flachen Fläche
- [x] **Docs für Spieler:** Was ist Whowolf, so spielt ihr, Rollen, was ihr braucht, Sicherheit, wie die App funktioniert, Herkunft; die Planungsdokumente getrennt unter „Für Entwickler“

**Fertig, wenn:** Eine **erste Testrunde** mit 5+ Leuten ohne Wolfsspur von Anfang bis Ende funktioniert hat.

## MVP-Sprint (bis 2026-11-01)

**Ziel:** Ein MVP, das man Freunden zeigen kann: stabil, schön, mit genug Rollen für richtige Runden. Statt Testabenden (früher M5) sichern **definierte automatische Tests** die Zuverlässigkeit ab. Die volle Wolfsspur (früher M4) kommt nach dem MVP, ins MVP kommt eine einfache Version.

### S – Stabiles Netz ([Task 002](tasks/002-stabiles-netz.md))

- [x] Zustand mit Versionsnummer; veraltete Nachrichten werden verworfen
- [x] Aktionen mit Nummer, Bestätigung und Doppel-Erkennung (keine Stimme geht verloren oder zählt doppelt)
- [x] Pausenmodus: Fehlt der Host, frieren die Timer ein, alle sehen eine ruhige Pause statt eines Fehlers; Apps warten die ganze Spielsitzung
- [x] Host wiederfinden: Bonjour-Suche nach Raum und Schlüssel statt fester IP, WLAN und Relay parallel
- [x] Android: Vordergrund-Dienst für den Host; iOS: Hinweis, die App offen zu lassen
- [x] Chaos-Tests: simuliertes Netz mit Verlust, Verzögerung, Doppelungen, Vertauschen und Host-Abstürzen; jede Partie endet regelkonform, alle Sichten stimmen überein
- [x] Nahtlos zurück: Wer rausfliegt, verbindet sich von selbst neu; nach einem App-Neustart springt die App direkt zurück an den Tisch (Spieler und Gastgeber); eine abwesende Person hält keine Phase auf
- [ ] Auf echten Geräten: Host schließt die App mitten in der Abstimmung und öffnet sie nach 30 s wieder

### D – Mondbühne in der App ([Task 003](tasks/003-mondbuehne-app.md))

- [ ] Einheitliches Design aus den gemeinsamen Tokens: Papier, Pappkarten, Bühnenrahmen, Lilita One; verspielt, aber ernst zu nehmen
- [ ] Figuren als Pappmodell mit Tiefe: beim Drehen eine echte Kartonkante, Rückseite aus dem Umriss (graue Pappe, Stempel); in App und Website gleich
- [ ] Jeder Bildschirm durchdacht: Start, Lobby, Rolle, Nacht, Morgen, Tag, Abstimmung, Ende, Pause

### F – Rollen, Einstellungen, Figuren ([Task 004](tasks/004-rollen-und-einstellungen.md), [Task 005](tasks/005-figuren.md))

- [x] Rollen Hexe, Jäger, Amor (mit Liebespaar) in `game_core`, mit Tarnaufgaben für alle
- [x] Alles Eigene optional, in Stufen: **Klassisch** (wie das Kartenspiel, nur mit der App als Erzähler) → **Whowolf** (Schäfchen, Gähnen, Atmosphäre) → **Volle Bühne**; danach jede Einstellung einzeln (Regeln und Protokoll; Bildschirme in der App folgen)
- [x] Einstellungen: Rollen und Anzahl, Phasenzeiten, Rollen nach dem Tod aufdecken, Schäfchen, Wolfsspur, Figurenwahl, Erzählstimme (`GameSettings` und Absicht `settings`; Einstellungsseite in der App folgt)
- [ ] Gleich viele weibliche und männliche Figuren (neue Figurenbilder im Mondbühnen-Stil)

### W – Wolfsspur light ([Task 006](tasks/006-wolfsspur-light.md))

- [ ] Morgen-Gähnen auf allen Geräten und ein paar Atmosphäre-Geräusche in der Nacht, ohne genauen Uhrabgleich; Einstellung aus/an

**Fertig, wenn:** Alle Chaos-Tests grün sind, eine Runde mit 6 Rollen auf echten Geräten ohne Abbruch durchläuft, auch wenn der Host die App kurz schließt, und 0.1 veröffentlicht ist.

## M6 – Release 0.1 ([Task 007](tasks/007-release-0-1.md))

**Ziel:** Whowolf ist öffentlich herunterladbar und verständlich präsentiert.

- [ ] Visuelle Identität aus Spur D in der App angekommen
- [ ] Release-Pipeline (GitHub Actions bei Tag `v*`): Android-APK (signiert), macOS, Windows, Linux → **GitHub-Release** mit Changelog, **SHA-256-Prüfsummen** und **Build-Provenance** (Artifact Attestations)
- [ ] Sicherheits-Check vor dem Release: Bedrohungsmodell durchgehen, `osv-scanner`, Secret-Scan
- [ ] **Externer Review des Handshakes** (`packages/secure_channel`) durch jemanden mit Krypto-Erfahrung (bis 2026-11-01 nicht zu schaffen: 0.1 bleibt als Entwickler-Beta gekennzeichnet, der Review ist Pflicht vor den Stores)
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
2. **Volle Wolfsspur** (früher M4, [NIGHT_SOUNDS.md](NIGHT_SOUNDS.md)): Uhrabgleich mit dem Host, synchrones Abspielen, Spur-Regel, Überdecken, Stummschalter auf iOS umgehen, Kopfhörer erkennen, Startwerte per Simulation mit Bots, eigene bzw. lizenzfreie Geräusche.
3. **Mehr Spiel:**
   - Beschützer
   - Eulenspur und eigene Whowolf-Rollen (Fährtenleger, Lauscher, Stille Pfote)
   - Beitritt während der Partie
   - menschlicher Erzähler, Story am Ende, Geistermodus
4. **Host-Übernahme:** Fällt das Host-Gerät ganz aus, übernimmt ein Spieler. Der Spielstand liegt dafür verschlüsselt verteilt bei den Spielern, und nur mehrere zusammen können ihn öffnen (Secret Sharing), damit niemand allein schummeln kann.
5. **Eigene Figuren (nur notiert, noch nicht umsetzen):** In der App eigene Figuren mit einem kleinen Zeichenprogramm erstellen. Für die Fähigkeiten einer Figur bieten wir eine Schnittstelle an. Hat jemand im Raum eine eigene Figur, wird sie automatisch an alle geteilt; jeder entscheidet, ob er sie offline behalten oder immer ignorieren will. Sicherheit: geteilte Figuren sind nur Daten (keine ausführbaren Inhalte), mit festen Größen- und Formatgrenzen, strenger Prüfung und Zustimmung pro Gerät.
6. **Design & Atmosphäre:** Rollen-Artwork, Stimmen, Musik, Stimmungen, Animationen.
7. **Stores:** Google Play (25 $ einmalig) und App Store, Datenschutzerklärung, Store-Einträge.
8. **Server (ganz zum Schluss):**
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
