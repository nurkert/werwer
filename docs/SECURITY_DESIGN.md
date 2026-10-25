# Sicherheitskonzept (Secure by Design)

> Status: Entwurf, gilt ab dem ersten Commit. Wird mit jedem Meilenstein überprüft. Öffentliche Meldewege für Schwachstellen: [`SECURITY.md`](../SECURITY.md).

## Grundsätze

1. **Was ein Gerät nicht wissen darf, bekommt es nie.** Weder verschlüsselt noch in der Oberfläche versteckt noch „nur im Speicher“. Gefiltert wird immer beim Host (`viewFor`).
2. **Dem Netz wird nichts geglaubt.** Jede Nachricht wird geprüft: Format, Größe, Absender, Phase, Regel.
3. **Identität kommt von der Verbindung, nie aus der Nachricht.** Eine Nachricht „ich bin Spieler X“ zählt nichts. Es zählt nur die Sitzung, an die die Verbindung gebunden ist.
4. **Kleine Angriffsfläche.** Nur ein offener Port, nur während eines Spiels, nur im lokalen Netz, nur ein Protokoll.
5. **Keine eigene Kryptografie.** Nur etablierte Protokollmuster und geprüfte Bibliotheken.
6. **Datensparsam.** Kein Konto, kein Tracking, keine Analytics. Im MVP verlässt nichts das lokale Netz.
7. **Sichere Voreinstellungen.** Alles Sicherheitsrelevante ist ab Werk an und nicht abschaltbar.
8. **Lieferkette absichern.** Wenige Abhängigkeiten, gepinnte Versionen, nachvollziehbare Releases.

## Was schützen wir? (Schutzgüter)

| Schutzgut | Warum wichtig |
|---|---|
| **Geheimnisse des Spiels:** Rollen, Nachtaktionen, Spuren | Ohne sie gibt es kein Spiel. Sie sind das eigentliche Schutzgut. |
| **Die Geräte der Spieler,** vor allem das Host-Handy mit offenem Port | Ein Fehler im Host darf kein Einfallstor ins Handy sein. |
| **Spielernamen und Sitzungen** | Wenige, aber personenbezogene Daten. Niemand soll fremde Sitzungen übernehmen. |
| **Vertrauen in Downloads** | Eine manipulierte APK unter unserem Namen wäre ein großer Schaden. |
| **Später: Verfügbarkeit des Relay-Servers** | Ein Ausfall oder Missbrauch würde alle Online-Runden treffen. |

## Wer greift an? (Angreifer)

| Angreifer | Wahrscheinlichkeit | Typische Angriffe |
|---|---|---|
| **A1 – Schummelnder Mitspieler** | **hoch**, der realistischste Fall | Netzverkehr mitlesen, modifizierte App, fremde Aktionen vortäuschen, Sitzung eines anderen übernehmen |
| **A2 – Fremde im selben WLAN** (Café, WG, Wohnheim) | mittel | ungebeten beitreten, mitlesen, Host stören (DoS), Parser des Hosts angreifen, sich als Host ausgeben (MITM) |
| **A3 – Präparierter QR-Code oder Link** | mittel | App zu fremdem Host lenken, Parser-Fehler ausnutzen, Phishing |
| **A4 – Lieferkette** | gering, aber folgenschwer | kompromittiertes Paket, manipulierte GitHub Action, gefälschtes Release |
| **A5 – Internet** (erst mit Server) | später | Raumcodes durchprobieren, Relay überlasten, Missbrauch |

## Bedrohungen und Gegenmaßnahmen

### Spielgeheimnisse (A1, A2)

- **Gefilterte Sichten beim Host:** Jeder Client bekommt nur `viewFor(sich selbst)`. Tests stellen für **jeden** Spieler sicher, dass keine fremden Rollen, Nachtaktionen oder Spuren enthalten sind (schon in Task 001).
- **Ende-zu-Ende-Verschlüsselung jeder Verbindung** (siehe [unten](#verbindung-und-beitritt)). Wer im WLAN mitschneidet, sieht nur Chiffretext.
- **Seitenkanäle im Netz:**
  - Auch verschlüsselter Verkehr verrät etwas über **Größe, Anzahl und Zeitpunkt** der Nachrichten. Werwölfe bekommen nachts die Stimmen ihrer Rudelmitglieder, also mehr Nachrichten. Ein Mitschneider könnte so die Wölfe erkennen.
  - Gegenmaßnahme: In geheimen Phasen bekommt **jeder Client gleich viele Nachrichten zu denselben Zeitpunkten**, auf feste Größenstufen aufgefüllt (Padding). Das ist das Anti-Tell-Prinzip, angewandt auf das Netzwerk.
- **Seitenkanäle in der Oberfläche:** Jeder Nacht-Bildschirm sieht gleich aus und dauert gleich lange, ob Wolf, Seherin oder Tarnaufgabe. Keine Vibration, keine Töne, die die Rolle verraten. Die Wolfsspur ist die einzige, bewusst gestaltete Ausnahme.
- **Logs:** Release-Builds protokollieren keine geheimen Spielinhalte (Rollen, Ziele, Tokens).
- **Ehrliche Grenze: Das Host-Gerät kennt alles.** Wer den Host mit einer **selbst modifizierten App** betreibt, kann schummeln. Das ist wie bei Karten: Wer mischt, könnte gezinkt mischen. Wir dokumentieren das offen, die normale App zeigt dem Host-Spieler nur seine eigene Sicht. Für Runden ohne vertrauenswürdigen Host gibt es später den **Server als Spielleiter**.
- **Modifizierte Clients** sehen trotzdem nur ihre eigene Sicht. Sie können höchstens Geräusche unterdrücken, was dasselbe ist wie Stummschalten, und das ist Teil der Spielmechanik.

### Verbindung und Beitritt

**Ziel:** Nur wer eingeladen ist, kommt rein. Niemand kann mitlesen. Niemand kann sich als Host ausgeben.

- **Der QR-Code ist der vertrauenswürdige Kanal.** Er wird am Tisch vom Host-Bildschirm gescannt und enthält:
  - die Adresse des Hosts im WLAN
  - den **öffentlichen Schlüssel** (bzw. dessen Fingerabdruck) des Hosts für diese Partie
  - ein **Raumgeheimnis** mit hoher Zufälligkeit (≥ 128 Bit)
- **Handshake nach einem etablierten Muster:** Vorgesehen ist ein Noise-Protokoll mit bekanntem Host-Schlüssel und Raumgeheimnis, etwa `NKpsk`. Das ergibt:
  - Der Client prüft, dass er wirklich mit diesem Host spricht. Damit sind Man-in-the-Middle-Angriffe im WLAN ausgeschlossen.
  - Nur wer den QR-Code hat, kommt in die Verschlüsselung.
  - Forward Secrecy und authentifizierte Verschlüsselung (AEAD) für jede Nachricht.
  - Umgesetzt wird das mit einer geprüften Bibliothek, Auswahl und Review in M2.
- **Warum nicht einfach TLS?** Browser akzeptieren keine selbst signierten Zertifikate ohne Warnung. Unsere eigene Verschlüsselung funktioniert dagegen gleich über LAN, über das spätere Relay und im Browser. Das Relay sieht dann **nur Chiffretext**.
- **Geheimnisse im QR-Link** stehen im **Fragment** (`#…`). Browser schicken es nie an einen Server, auch nicht später an `whowolf.de`.
- **Schlüssel pro Partie:** Der Host erzeugt für jeden Raum ein neues Schlüsselpaar. Wird ein QR-Code abfotografiert, ist er nach der Runde wertlos.
- **Manueller Beitritt ohne QR** (Raumcode + IP): Hier fehlt der vertrauenswürdige Kanal. Deshalb muss der Host **jeden Beitritt bestätigen**, und beide Geräte zeigen ein kurzes Prüfbild an (z. B. drei Symbole), das man am Tisch vergleicht.
- **Sitzungstokens:** 128 Bit zufällig, pro Spieler und Raum. Sie liegen im sicheren Speicher des Geräts (Keychain/Keystore) und werden nie protokolliert. Ein Rejoin geht nur mit dem Token. Eine neue Verbindung mit dem Token löst die alte ab.
- **Rechteprüfung jeder Absicht:** Der Host prüft immer, ob diese Sitzung das darf (richtige Phase, lebendig, passende Rolle). Die Spielregeln selbst prüft `game_core`.

### Das Host-Gerät als kleiner Server (A2)

- Der Port ist **nur während eines Raums offen** und wird danach sofort geschlossen.
- Er lauscht **nur auf lokalen Netzwerkschnittstellen**.
- Es gibt **nur einen Endpunkt** (WebSocket mit unserem Protokoll), keine weiteren Dienste. Später kommt eventuell statische Auslieferung der Web-App dazu, ohne Verzeichnislisten und ohne Pfadtricks.
- **Grenzen gegen Überlastung:**
  - maximale Nachrichtengröße
  - maximale Anzahl an Verbindungen
  - Zeitlimit für den Handshake
  - Ratenbegrenzung pro Verbindung
  - halb offene Verbindungen werden aufgeräumt
- **Strenges Parsen:**
  - versionierte, explizit typisierte Nachrichten
  - unbekannte Felder oder Typen werden abgelehnt
  - kein dynamisches Ausführen
- **Fuzz- bzw. Property-Tests** für Parser und Protokoll: Zufällige und kaputte Eingaben dürfen nie abstürzen und nie den Zustand verändern.

### QR-Codes und Links (A3)

- **Strikte Prüfung:**
  - nur `https://whowolf.de/join` bzw. später das Schema der App
  - genau die erwarteten Parameter
  - Längenbegrenzung
- **Die lokale Adresse muss privat sein:**
  - erlaubt sind private IPv4-Bereiche (RFC 1918), Link-Local und IPv6 ULA/Link-Local
  - nie eine öffentliche Internetadresse
  - so kann ein präparierter Code die App nicht zu fremden Servern lenken
- **Vor dem Verbinden anzeigen**, wem man beitritt (Name des Hosts, Raum), und erst nach Bestätigung verbinden.

### Daten auf dem Gerät

- **Gespeichert wird nur das Nötigste:**
  - eigener Name
  - Sitzungstoken (im sicheren Speicher)
  - beim Host der laufende Spielstand
- **Den Spielstand speichert der Host nur im App-Sandkasten.** Nach dem Spiel wird er gelöscht. Er enthält alle Rollen und wird deshalb nie exportiert oder geteilt.
- **Keine Berechtigungen auf Vorrat:**
  - die Kamera erst beim Scannen
  - „Lokales Netzwerk“ erst beim Erstellen bzw. Beitreten
  - kein Standort, keine Kontakte, kein Mikrofon

### Lieferkette und Releases (A4)

- **Wenige Abhängigkeiten.**
  - Jede neue Abhängigkeit wird geprüft: Wer pflegt sie (verifizierter Publisher)? Unter welcher Lizenz? Wie aktiv ist sie? Brauchen wir sie wirklich?
  - Die Begründung kommt in `DECISIONS.md`, wenn es nicht trivial ist.
- **`pubspec.lock` wird eingecheckt.** Updates kommen bewusst über Dependabot-PRs mit grüner CI.
- **Schwachstellen-Scan:** `osv-scanner` prüft `pubspec.lock` in der CI.
- **GitHub Actions:**
  - auf **Commit-SHA gepinnt**
  - `permissions:` mit minimalen Rechten (Standard: nur lesen)
  - keine `pull_request_target`-Workflows mit Code aus Forks
- **Repo-Einstellungen:**
  - Branch-Schutz für `main` (CI muss grün sein)
  - Secret Scanning mit Push Protection
  - private Schwachstellenmeldung aktiviert
- **Keine Geheimnisse im Repo:**
  - Signierschlüssel liegen nur als GitHub-Secrets bzw. lokal in git-ignorierten Dateien
  - zusätzlich prüft ein Secret-Scan (z. B. gitleaks) in der CI
- **Releases:**
  - werden nur von der CI gebaut, nie von Hand hochgeladen
  - mit **SHA-256-Prüfsummen** und **Build-Provenance** (GitHub Artifact Attestations), damit jeder prüfen kann, dass der Download aus diesem Repo stammt
  - die Android-APK ist mit unserem Release-Schlüssel signiert
  - macOS/iOS später signiert und notarisiert

### Website

- Statisch, nur HTTPS (erzwungen).
- Keine Tracker, keine Fremd-Skripte, keine Cookies.
- Content-Security-Policy, soweit GitHub Pages es zulässt (Meta-Tag).

### Später: Relay-Server (A5)

- Der Server sieht dank Ende-zu-Ende-Verschlüsselung **nur Chiffretext** und speichert nichts dauerhaft.
- **Raum-IDs mit hoher Zufälligkeit.** Beitreten geht nur mit dem Geheimnis aus dem QR-Code.
- Ratenbegrenzung, Limits für Verbindungen und Räume, Zeitlimits.
- Container ohne Root-Rechte, minimales Image.
- Ehrlich dokumentiert, was der Server trotzdem sieht: IP-Adressen, Zeitpunkte, Nachrichtengrößen.

## Sicherheit im Entwicklungsablauf

- **Jede neue Netzwerk- oder Speicherfunktion** bekommt vor dem Merge einen kurzen Abschnitt „Sicherheit“: Was kann schiefgehen? Was schützt dagegen? Welcher Test prüft das?
- **Sicherheitsrelevante Tests** (Informationslecks, Parser-Fuzzing, Rechteprüfung, Handshake mit falschem Schlüssel oder Geheimnis) laufen in der normalen CI und blockieren den Merge.
- **Vor jedem Release:** Diese Datei durchgehen, das Bedrohungsmodell aktualisieren und `osv-scanner` sowie den Secret-Scan prüfen.
- **Vor 1.0** ist ein externer Blick wünschenswert, etwa ein Review des Handshakes durch jemanden mit Krypto-Erfahrung.

## Offene Entscheidungen

- Konkrete Bibliothek bzw. Implementierung für den Noise-Handshake in Dart, auch im Browser lauffähig (M2).
- Größenstufen und Takt für das Padding in geheimen Phasen (M2).
- Prüfbild beim manuellen Beitritt: Symbole oder Zahlen (M3).
