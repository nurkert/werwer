# Roadmap

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
| Android, macOS, Windows, Linux als Download; iOS über TestFlight | App Store, Google Play |
| Minimales eigenes Logo, Icon und Farben | Rollen-Artwork, Animationen |

---

## M0 – Fundament

**Ziel:** Das Repo ist bereit für die Entwicklung, und Entscheidungen, die man später nur schwer ändern kann, sind getroffen.

- [x] Vision, Name (**Whowolf**), Lizenz (Apache 2.0), Repo, [Marktanalyse](MARKET.md)
- [ ] Dart-Workspace + `packages/game_core` + strikte Lints (Task 001)
- [ ] CI von Anfang an: GitHub Actions mit `dart analyze`, `dart format --set-exit-if-changed` und Tests bei jedem Push
- [ ] **Früh festlegen, später teuer:**
  - [ ] App-ID / Bundle-Identifier (z. B. `io.github.nurkert.whowolf`). Lässt sich nach einem Store-Release nicht mehr ändern.
  - [ ] Format des QR-Links (siehe [unten](#von-anfang-an-mitdenken)) und die Domain dafür. Anfangs reicht die GitHub-Pages-Adresse.
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
- [ ] Tests: jede Regel, komplette Partien über die öffentliche API, kein Informationsleck in den Sichten

**Fertig, wenn:** Die Akzeptanzkriterien aus Task 001 erfüllt sind und der Zustand verlustfrei in JSON und zurück geht.

## M2 – Host & lokales Netzwerk

**Ziel:** Mehrere Geräte spielen über das WLAN eine Partie. Zum Testen reicht ein Kommandozeilen-Client, es braucht noch keine App.

- [ ] **Host-Logik** in reinem Dart (eigenes Paket, z. B. `packages/game_host`): Raum, Raumcode, Spieler-Sitzungen, Timer. Uhr und Zufall werden injiziert.
- [ ] **Protokoll:** versionierte JSON-Nachrichten (Absichten rein, gefilterte Sichten + Ereignisse raus), eigenes Paket `packages/protocol`
- [ ] **Transport-Schnittstelle** mit In-Memory-Transport für Tests und LAN-WebSocket-Transport (`dart:io`, nur im Plattform-Teil)
- [ ] **Rejoin** per Sitzungstoken mit vollem Status; der Host speichert den Spielstand laufend und kann nach einem Absturz weitermachen
- [ ] Integrationstest: Host + mehrere Clients spielen über den In-Memory-Transport eine ganze Partie, inklusive Verbindungsabbruch und Rejoin

**Fertig, wenn:** Zwei Rechner im selben WLAN über den Kommandozeilen-Client eine Partie spielen können und ein abgebrochener Client mit seinem Status zurückkommt.

## M3 – App: spielbarer Prototyp

**Ziel:** Mit Freunden eine echte Runde spielen, mit der App auf jedem Handy.

- [ ] Flutter-App im Workspace, Mehrsprachigkeit (Deutsch/Englisch) von Anfang an
- [ ] Start: Name eingeben → „Raum erstellen“ oder „Beitreten“
- [ ] Beitreten: **QR-Scanner in der App**, Fallback Raumcode + IP manuell
- [ ] Lobby: **Tischkreis aus der eigenen Perspektive**, Sitzordnung festlegen und korrigieren, Rollenvorschlag, Start
- [ ] Spielbildschirme: Rolle ansehen → Nacht (Aktion bzw. Tarnaufgabe) → Morgen → Tag (wer lebt, Bildschirm dimmen) → Abstimmung → Sieg
- [ ] Erzähler: Text auf allen Geräten, Sprachausgabe auf dem Host-Gerät
- [ ] Bildschirm bleibt an (Wakelock), sauberes Reconnect nach Sperren oder Netzwechsel
- [ ] **Netzwerk-Fallstricke abfangen** und Hilfe anzeigen:
  - iOS-Berechtigung „Lokales Netzwerk“
  - Firewall-Freigabe auf dem Desktop
  - Gäste-WLAN mit Client-Isolation, Ausweg: Hotspot des Host-Handys
- [ ] Läuft auf Android, iOS, macOS, Windows, Linux

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

- [ ] Minimale visuelle Identität: Logo, App-Icon, Farben, Schrift (alles eigen bzw. frei lizenziert)
- [ ] Release-Pipeline (GitHub Actions bei Tag `v*`): Android-APK, macOS, Windows, Linux → **GitHub-Release** mit Changelog
- [ ] iOS über **TestFlight**. Dafür braucht es den Apple Developer Account (99 $/Jahr), alternativ iOS erst nach 0.1.
- [ ] **Website** auf GitHub Pages: Was ist Whowolf, Downloads, Spielregeln, Wolfsspur erklärt, Mitmachen
- [ ] Datenschutz (keine Daten, kein Tracking) und Impressum für die Website prüfen
- [ ] `CONTRIBUTING.md`, Issue-Templates, README aktualisieren
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
   - Beitrittsseite `/r/<raumcode>` mit Deep Links
   - eigener Server in den Einstellungen
   - Docker-Image und offizieller Server
   - optional: Server als Spielleiter

---

## Von Anfang an mitdenken

Damit der Server später ohne viel Arbeit andockt. Nichts davon wird für das MVP extra gebaut, es ist nur die Art, **wie** wir bauen:

- **Host-Logik in reinem Dart**, ohne Flutter und ohne `dart:io`. Uhr und Zufall werden injiziert. So läuft sie später unverändert auch auf einem Server.
- **Transport hinter einer Schnittstelle**, und der Host kann mehrere gleichzeitig bedienen. Das Relay ist dann nur ein weiterer Transport.
- **Ein versioniertes Protokoll** für lokal und Server. Die Pakete `protocol` und `game_host` sind schon so geschnitten, dass ein `server/` sie einfach importiert.
- **Spieler über Sitzungstoken identifizieren**, nicht über die Verbindung.
- **Spielzustand serialisierbar.**
- **Der QR-Code ist von Anfang an ein Link** auf eine Domain, die wir kontrollieren, z. B. `https://<domain>/join?room=ABCD&lan=192.168.0.5:4040`:
  - Im MVP liest nur die App den `lan`-Teil.
  - Später kommt die Server-Adresse dazu, und dieselbe URL wird zur Beitrittsseite im Browser.
  - Alte Apps verstehen neue Codes weiterhin.
- Die App kennt nur „eine Verbindung zu einem Host“, nicht, wo er läuft.
