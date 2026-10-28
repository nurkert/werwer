# Sicherheitskonzept (Secure by Design)

> Status: Entwurf, gilt ab dem ersten Commit. Wird mit jedem Meilenstein überprüft. Öffentliche Meldewege für Schwachstellen: [`SECURITY.md`](../SECURITY.md).

## Grundsätze

1. **Was ein Gerät nicht wissen darf, bekommt es nie.** Weder verschlüsselt noch in der Oberfläche versteckt noch „nur im Speicher“. Gefiltert wird immer beim Host (`viewFor`).
2. **Dem Netz wird nichts geglaubt.** Jede Nachricht wird geprüft: Format, Größe, Absender, Phase, Regel.
3. **Identität kommt von der Verbindung, nie aus der Nachricht.** Eine Nachricht „ich bin Spieler X“ zählt nichts. Es zählt nur die Sitzung, an die die Verbindung gebunden ist.
4. **Kleine Angriffsfläche.** Nur ein offener Port, nur während eines Spiels, nur im lokalen Netz, nur ein Protokoll.
5. **Keine eigene Kryptografie.** Nur geprüfte Bibliotheken (libsodium) und deren dokumentierte Bausteine; keine selbst gebauten Primitive, Schlüsselableitungen, MACs oder Nonce-Verwaltung.
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
- **Handshake aus libsodium-Bausteinen** (`crypto_kx`, schlüsselbehafteter BLAKE2b-Hash, `crypto_secretstream`). Das ergibt:
  - Der Client prüft, dass er wirklich mit diesem Host spricht. Damit sind Man-in-the-Middle-Angriffe im WLAN ausgeschlossen.
  - Nur wer den QR-Code hat, kommt in die Verschlüsselung.
  - Authentifizierte Verschlüsselung für jede Nachricht, Schutz gegen Wiederholen und Vertauschen. Forward Secrecy pro Raum: Jeder Raum hat ein neues Schlüsselpaar, das mit dem Raum gelöscht wird.
- **Warum nicht einfach TLS?** Browser akzeptieren keine selbst signierten Zertifikate ohne Warnung. Unsere eigene Verschlüsselung funktioniert dagegen gleich über LAN, über das spätere Relay und im Browser. Das Relay sieht dann **nur Chiffretext**.
- **Geheimnisse im QR-Link** stehen im **Fragment** (`#…`). Browser schicken es nie an einen Server, auch nicht später an `whowolf.de`.
- **Schlüssel pro Partie:** Der Host erzeugt für jeden Raum ein neues Schlüsselpaar. Wird ein QR-Code abfotografiert, ist er nach der Runde wertlos.
- **Manueller Beitritt ohne QR** (Raumcode + IP): Hier fehlt der vertrauenswürdige Kanal. Deshalb muss der Host **jeden Beitritt bestätigen**, und beide Geräte zeigen ein kurzes Prüfbild an (z. B. drei Symbole), das man am Tisch vergleicht. Ein Commitment im Handshake verhindert, dass ein Angreifer in der Mitte passende Schlüssel durchprobiert. Nach dem Reinlassen bekommt der Spieler das Raumgeheimnis, damit jeder spätere Rejoin über den geprüften Kanal läuft.
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

### Die klassische Nacht (A1)

- Die Länge eines aufgerufenen Schritts verrät nichts:
  - Jeder Schritt läuft mindestens `calledStepTime` (8 s), auch wenn die Rolle schneller wählt, und eine tote Rolle wird genauso lange aufgerufen.
  - Die Restzeit sehen nur die Aufgerufenen, die Wartezahl ist in dieser Nacht für alle 0.
  - Sonst verrieten sie, wann jemand gewählt hat, ob Seherin oder Hexe noch lebt und wie viele Wölfe es gibt (gefunden im Review vom 2026-10-26).
- Die Wölfe müssen sich einig sein, bevor ihr Schritt enden kann; bis zum Ablauf der Zeit dürfen sie umentscheiden.
- **Tests:** `packages/game_core/test/called_night_test.dart`, `packages/game_host/test/called_night_host_test.dart`.

### Der Erzähler (A1)

- Was gesagt wird, wann und wo, ist eine reine Funktion öffentlicher Werte: Übergang der Sicht, Raum, Runde, Sitzordnung, Phasenbeginn in Host-Zeit und öffentliche Fakten (`storyFacts`: ob schon jemand gestorben ist, Werwolf-Anzahl und Rollen aus den Einstellungen). Keine Fassung hängt von einer lebenden Rolle oder einer Nachtwahl ab, auf allen Handys läuft dasselbe.
- **Intro überspringen:** `SkipIntroIntent` darf nur der Spielleiter senden, nur in der Rollenvergabe und nur einmal (sonst `Refused`). Der Host setzt den Zeitpunkt selbst (seine Uhr), der Spieler liefert keinen Wert. Er steht nur während der Rollenvergabe im Spielstand.
- **Tests:** `app/test/narration_script_test.dart`, `app/test/walking_narrator_test.dart`, `packages/game_host/test/host_test.dart` („only the owner skips the intro …“).

### Host-Übernahme (A1, A2)

- **Kein Gerät allein liest den Raum:**
  - Der Nachfolger bekommt nur das Chiffrat (secretstream mit Final-Tag, Epoche als Zusatzdaten), der Zeuge nur den Schlüssel.
  - Der Schlüssel wechselt bei jedem neuen Paar, und wer seinen Teil verliert, bekommt die Anweisung, ihn zu löschen.
- **Zwei unabhängige Stimmen:**
  - Der Zeuge gibt den Schlüssel nur heraus, wenn er den Host selbst länger als 6 s vermisst, oder wenn der Host selbst die Übergabe anordnet (über den geprüften Kanal).
  - Ein manipulierter Nachfolger allein kommt also nie an die Rollen.
- **Gegenseitige Authentisierung:**
  - Der Kandidaten-Eingang nimmt nur Handshakes mit dem Kandidatengeheimnis an (QR-Muster), und das kennt außer dem Nachfolger nur der Zeuge.
  - Den Handshake zum Kandidatenschlüssel besteht nur der echte Nachfolger. Ein Fremder im WLAN bekommt weder den Schlüssel noch einen Platz.
- **Kein neuer offener Endpunkt im Normalbetrieb:**
  - Der Eingang ist nur nach Host-Verlust offen, auf einem eigenen Port und mit den bestehenden Grenzen (`maxHandshakes`, Zeitlimit).
  - Jede Verbindung darf genau eine Nachricht senden und wird danach geschlossen.
  - Ein falscher Schlüssel öffnet nichts.
- **Kein Lahmlegen durch Behauptungen:**
  - Eine höhere Epoche in einem Hello oder in einer Bonjour-Ankündigung ist nur ein Hinweis.
  - Der Host tritt erst zurück, wenn er sich mit seinen eigenen Raumschlüsseln und dem Token des Spielleiters beim neueren Host angemeldet hat. Das kann nur ein echter Nachfolger beantworten.
- **Grenzen:**
  - Nachfolger und Zeuge zusammen könnten den Raum lesen.
  - Der neue Host hat danach dasselbe Vertrauen wie jedes Host-Gerät.
  - Aktionen aus den letzten Millisekunden vor einem harten Ausfall können fehlen; der Spieler sieht das und tippt erneut.
  - Die Größe des Verkehrs verrät, wer Nachfolger ist.
  - Übernahmen laufen nur im WLAN, Relay-Spieler warten wie bisher.
- **Tests:**
  - `packages/game_host/test/takeover_test.dart`: ganze Partien mit Absturz, Übergabe, nur einseitigem Verbindungsverlust, falschem Schlüssel, zurückkehrendem altem Host und behaupteter Epoche.
  - `packages/secure_channel/test/custody_test.dart`: Siegel und Eingang.
  - `app/integration_test/takeover_test.dart`: alles echt auf macOS.

### Die Web-App vom Host (A2, A3)

- **Lieferung:** Das Host-Handy liefert die Web-App an Browser im lokalen Netz aus, über denselben LAN-Server und nur an private Adressen. Erlaubt sind nur GET und HEAD.
- **Strenge Pfade:** nur Buchstaben, Ziffern, `._-/`, keine Punkt-Segmente, höchstens 200 Zeichen. Ausgeliefert wird nur, was im App-Bundle liegt; es gibt keinen Dateisystemzugriff.
- **Header:**
  - CSP `default-src 'self'`, Skripte nur vom Host (plus `wasm-unsafe-eval` für CanvasKit und libsodium)
  - Verbindungen nur zum Host selbst
  - `frame-ancestors 'none'`, `nosniff`, `no-referrer`, COOP
- **Keine Drittanbieter:** Die Web-App lädt nichts aus dem Internet, weder CDN noch Schriftendienst noch Service Worker.
- **Schlüssel:** Der QR-Code verweist auf `http://<private Adresse>/join?…#k=…&s=…`. Die Schlüssel stehen im Fragment, das der Browser nie sendet. Ein solcher Link gilt nur mit Schlüssel, der Handshake beweist also, dass die Seite vom echten Host stammt. Nach dem Lesen entfernt die Seite den Schlüssel aus Adresszeile und Verlauf.
- **Restrisiko:** Die Seite selbst kommt über unverschlüsseltes HTTP im WLAN. Ein aktiver Angreifer im selben Netz könnte eine veränderte Web-App ausliefern. Das ist dasselbe Vertrauen wie bei jeder lokal ausgelieferten Seite; die Spieldaten bleiben Ende-zu-Ende verschlüsselt, solange die Seite echt ist. Wer das ausschließen will, nimmt die App.
- **Neu laden:** Damit ein Browser-Spieler nach dem Neuladen, in einem neuen Tab oder nach einem zweiten Scan an seinen Platz zurückkommt, liegen Link und Sitzungstoken pro Raum im `localStorage` dieses Geräts, höchstens 12 Stunden und höchstens 8 Räume. Der Tab merkt sich im `sessionStorage` nur, welcher Raum seiner ist. Am Spielende wird der Eintrag gelöscht. Keine Cookies. Wer das Gerät in dieser Zeit in die Hand bekommt, könnte an den Platz zurück; das ist dieselbe Grenze wie bei der App mit ihrem Sitzungsschlüssel (Task 017).
- **Tests:** `packages/game_host/test/site_test.dart` (Header, Ausbruchsversuche, nur lesen), `packages/protocol/test/link_test.dart` (lokale Links nur mit Schlüssel und privater Adresse).

### Die Web-App vom Server (A3, A5), Task 017

- **Opt-in:** Das Relay liefert die Web-App nur mit `WEB_APP_DIR` aus, unter `/v/<Protokoll>/<Build>/`. Ohne die Variable antwortet es auf diese Pfade nicht, auch nicht auf `HEAD`.
- **Vertrauen:** Wer die Seite ausliefert, kann die Schlüssel aus dem Fragment lesen. Im Browser vertraut man also dem Server, der den QR-Code ausgestellt hat. Die Beitrittsseite und die Datenschutzerklärung sagen das. Mit der App gibt es diese Abhängigkeit nicht. Mitspieler liefern nie aus, und es gibt keinen Tunnel vom Host durch das Relay: Kein fremder Code läuft je auf dem Ursprung des Servers.
- **Nur gebaute Builds:** Das Image enthält nur Builds aus `server/webapps.lock` (nur anhängen, Rückzug per `retire`) und den des laufenden Releases. `tool/fetch_webapps.sh` prüft jede Datei gegen ihre Prüfsumme und die Build-Attestation dieses Repositorys. Vor jedem Release startet `tool/verify_webapp.sh` den Build unter den echten Headern in Chrome.
- **Auslieferung:** Alles wird beim Start einmal in den Speicher gelesen, gleiche Inhalte nur einmal. Eine Anfrage ist ein Nachschlagen in einer Tabelle, nichts aus der Anfrage wird zu einem Pfad auf der Platte. Nur GET und HEAD, nur bekannte Medientypen, Grenzen pro Adresse (`MAX_REQUESTS_PER_MINUTE`), dieselben Header wie beim Host (`webAppHeaders`), Anfragen mit `Service-Worker`-Header abgelehnt. Das Relay schreibt keine Pfade und keine Adressen ins Log.
- **Türcodes (Task 022):** Mit Web-App vergibt das Relay pro Raum kurze Codes (6 Zeichen, 7 Minuten gültig, höchstens zwei pro Raum, sterben mit dem Raum). Auf der Codeseite (`/`, `/c?code=…`) führt ein Code zur Seite des Raums, **ohne** Schlüssel. Der Beitritt läuft also immer über das Prüfbild und die Bestätigung der Spielleitung. Höchstens 10 Versuche pro Adresse und Minute, richtig oder falsch. Keine Codes im Log, nichts aus der Anfrage in der Antwort, Seiten ohne Skript (`default-src 'none'`). `JoinLink.tryParseCodePage` liest nur die Web-App für ihre eigene Adresse; gescannte Links ohne Schlüssel zu einem Server bleiben abgelehnt.
- **Kein Raum aus dem Browser:** `/host` mit `Origin`-Header lehnt das Relay ab. Browser schicken ihn immer, die App nie. Keine Webseite kann also über die Browser ihrer Besucher Räume öffnen.
- **Server nur bei Bedarf:** Der Host öffnet seinen Raum auf dem Server erst, wenn er den QR-Code zeigt (oder ohne WLAN). Spieler im WLAN finden den Raum über Bonjour. Über Runden, die im WLAN bleiben, erfährt der Server nichts.
- **App-Links:** `.well-known`-Dateien gibt es nur aus der Konfiguration des Servers. Die App nimmt nur Seiten des offiziellen Servers mit Schlüssel an und fragt vor dem Beitritt wie nach einem Scan.
- **Tests:** `server/test/web_apps_test.dart` (Pfade, Methoden, Header, Grenzen, Service Worker, `Origin`, `.well-known`, kein Log), `server/test/browser_relay_test.dart` (echter Browser über das Relay), `packages/protocol/test/link_test.dart` (Server-Seiten nur mit Schlüssel, Browser nur zum eigenen Ursprung), `app/test/app_links_test.dart`, `app/test/invite_code_test.dart`, `app/integration_test/table_test.dart` (Server nur bei Bedarf), `server/test/door_test.dart` (Türcodes: kein Schlüssel, Ablauf, Rotation, Tod mit dem Raum, Rate-Limit, Eingaben, Frames).

### Platz an ein anderes Gerät (A1, A2)

- Nur die Sitzung des Spielleiters kann einen Code für einen Platz anlegen (`HandoverIntent`, sonst `notYourAction`). Der Code sind 16 Zufallsbytes vom Gerät des Spielleiters. Er gilt einmal und 2 Minuten, höchstens 4 sind offen, und der Platz des Hosts ist ausgenommen.
- Der Code steht im Fragment des QR-Codes neben Schlüssel und Raumgeheimnis. Er wird nur über einen geprüften Kanal angenommen; ein Gerät im WLAN ohne den QR-Code kann ihn also nicht einlösen, selbst wenn es ihn errät.
- Danach bekommt der Platz ein neues Token; das alte Gerät wird getrennt, und sein Token gilt nicht mehr. So sitzen nie zwei Geräte auf einem Platz.
- Tests: `packages/game_host/test/host_test.dart` (Gruppe „handing a seat to another device“), `packages/protocol/test/link_test.dart`.

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

### Relay-Server (A5)

- Der Relay sieht nur Chiffrat und Verbindungsdaten. Er kennt keine Spielregeln und keinen Spielstand und protokolliert keine Inhalte.
- **Speicher:** `dart:io` setzt eine WebSocket-Nachricht aus beliebig vielen Fragmenten zusammen und puffert Ausgabe ohne Grenze. Deshalb macht der Server den Handshake selbst (RFC 6455) und bewacht den rohen Socket (`game_host/socket_guard.dart`, auch im LAN-Host):
  - **Eingang:** Jedes Byte zählt gegen ein Budget pro Verbindung (256 KiB bei 64 KiB/s für Spieler, 4 MiB bei 1 MiB/s für Hosts).
  - **Nachrichten:** Der Server liest die Frame-Köpfe mit und zählt jede Nachricht über alle Fragmente (Spieler 8 KiB, Hosts 128 KiB). Eine unfertige Nachricht darf höchstens 10 s offen bleiben. Steuerframes sind kurz und nie fragmentiert.
  - **Ausgang:** Höchstens 256 KiB warten auf einen Empfänger. Wer 15 s lang nichts liest, wird getrennt.
  - Kompression ist aus.
- **Abstürze:** Jede Anfrage läuft in einem eigenen Fehlerfang, der ganze Prozess zusätzlich in einer Zone, die nur den Fehlertyp notiert. Wiederholte Header (z. B. zwei `Origin`) werden als Liste gelesen, nie mit `headers.value`, das dann wirft.
- **Web-App:** Komprimiert gehaltene Dateien werden nie auf Anfrage entpackt. Wer kein gzip annimmt, bekommt 406, so kostet keine Anfrage Rechenzeit nach fremdem Willen. Jede einfache Anfrage zählt gegen das Limit pro Adresse, auch `/health` und 404. Caddy trennt Clients, die ihre Header langsam schicken (`read_header 10s`, `idle 2m`).
- **Fluten:**
  - Grenzen für Verbindungen gesamt und pro Adresse sowie für neue Verbindungen pro Adresse und Minute; das macht auch das Durchprobieren von Raum-IDs aussichtslos.
  - Räume pro Adresse und Spieler pro Raum sind begrenzt, ebenso die Nachrichtenrate.
  - Die Grenzen werden nach dem Upgrade erneut geprüft.
- **Echte Adressen:** Hinter Caddy kommt die Adresse aus `X-Forwarded-For`, aber nur mit `TRUST_PROXY=1`. Das ist sicher, weil der Relay-Port nicht öffentlich ist und Caddy den Header des Clients überschreibt.
- **Betrieb:** Container read-only, ohne Capabilities, `no-new-privileges`, Speicher- und CPU-Grenze. Updates nur als signiertes Image aus dem Release-Workflow (Sigstore, gegen die Workflow-Identität geprüft), gestartet über den Digest. Der Server bietet dafür keinen Endpunkt an.
- **Tests:** `server/test/relay_test.dart` (riesiger Frame, Grenzen pro Adresse, Raum-IDs raten, Proxy-Adresse), `server/test/guard_test.dart` (doppelter Header, endlose Fragmente, liegengelassene Nachricht, Spieler, der nicht liest), `packages/game_host/test/player_link_test.dart` (ein ungeprüfter Host kann einen Spieler am Prüfbild nicht fluten).

## Sicherheit im Entwicklungsablauf

- **Jede neue Netzwerk- oder Speicherfunktion** bekommt vor dem Merge einen kurzen Abschnitt „Sicherheit“: Was kann schiefgehen? Was schützt dagegen? Welcher Test prüft das?
- **Sicherheitsrelevante Tests** (Informationslecks, Parser-Fuzzing, Rechteprüfung, Handshake mit falschem Schlüssel oder Geheimnis) laufen in der normalen CI und blockieren den Merge.
- **Vor jedem Release:** Diese Datei durchgehen, das Bedrohungsmodell aktualisieren und `osv-scanner` sowie den Secret-Scan prüfen.
- **Vor 0.1** soll jemand mit Krypto-Erfahrung den Handshake in `packages/secure_channel/lib/src/channel.dart` reviewen (rund 500 Zeilen, nur libsodium-Bausteine).

## Stand der Umsetzung (2026-10-26)

- **Ende-zu-Ende-Verschlüsselung (Handshake Version 3):** Jede Verbindung über WLAN oder Relay läuft durch `packages/secure_channel`, gebaut nur aus libsodium (Paket `sodium`, nativ mitgebaut, im Browser sodium.js):
  - **Mit QR-Code** (Host-Schlüssel und 256-Bit-Raumgeheimnis im Fragment `#k=…&s=…`): `crypto_kx` zwischen einem frischen Spielerschlüssel und dem Raumschlüssel; beide Sitzungsschlüssel werden mit dem Raumgeheimnis per schlüsselbehaftetem BLAKE2b gebunden. Der Spieler schickt zuerst eine Bestätigungsnachricht, der Host antwortet erst, wenn sie sich entschlüsseln lässt. Damit beweist der Spieler das Geheimnis und der Host seinen Schlüssel.
  - **Frischer Wert vom Host:** Pro Verbindung schickt der Host 32 frische Zufallsbytes, bevor der Spieler etwas Verschlüsseltes sendet; sie gehen in beide Richtungsschlüssel und ins Prüfbild ein. Eine aufgezeichnete Verbindung lässt sich deshalb nicht noch einmal abspielen (sonst könnte ein Mithörer oder das Relay Spieler per „ersetzt“ hinauswerfen).
  - **Ohne QR-Code:** Der Spieler legt sich mit einem Hash seines Schlüssels fest (Commitment), bevor der Host seinen Schlüssel und den frischen Wert zeigt. Das Prüfbild (4 von 16 Symbolen, 16 Bit) ergibt sich aus Spielerschlüssel, Host-Schlüssel und frischem Wert; ein Angreifer in der Mitte kann es nicht im Voraus passend rechnen, nur online raten (1 zu 65 536 pro Versuch). Der Host lässt höchstens 12 solcher Handshakes pro Minute zu (Raten würde Tage dauern), und der Gastgeber muss trotzdem zustimmen. Bis Handshake 2 war der Host-Beitrag der feste Raumschlüssel, so dass ein Angreifer im WLAN das Prüfbild offline passend rechnen konnte (gefunden im Sicherheits-Check vor 0.1).
  - **Danach** `crypto_secretstream_xchacha20poly1305` pro Richtung (eigene Nonces, Manipulations-, Wiederholungs- und Reihenfolgeschutz).
  - Schlüssel pro Raum, gespeichert nur zusammen mit dem Raum-Schnappschuss im App-Ordner (Seed, nicht der Schlüssel selbst).
- **Padding:** Jede Nachricht wird vor der Verschlüsselung auf feste Größenstufen (512 B, 2 KiB, 8 KiB, 32 KiB, ~64 KiB) aufgefüllt. **Takt:** Der Host schickt bei jeder Änderung allen denselben Zustand, die Anzahl der Nachrichten hängt also nicht von der Rolle ab.
- **Manipulation** einer Nachricht beendet die Verbindung; eine falsche Antwort im Handshake ebenso.
- **Beitritt ohne QR-Code:** Der Spieler muss selbst bestätigen, dass der Bildschirm des Gastgebers mit denselben Symbolen nach ihm fragt; vorher zählt nichts vom Host (kein Welcome, kein Spielstand, keine Schlüssel werden gespeichert). Sonst könnte ein eingeladener Mitspieler im WLAN einen falschen Raum anbieten, nie „Warten“ senden und das Prüfbild umgehen. Während des Wartens gilt Stille nicht als tote Verbindung (vorher wechselte das Prüfbild nach 8 s).
- **Geheime Spielwerte** (Türzeichen, Herdengrößen, Münze der Markierung) entstehen per HMAC-SHA256 aus einem 256-Bit-Geheimnis der Partie (`package:crypto` vom Dart-Team), das nur im Host-Schnappschuss liegt; aus den eigenen Werten lässt sich nichts über andere ausrechnen (vorher 32-Bit-Startwert mit FNV, in Sekunden rückrechenbar).
- **Namen** ohne Steuer- und unsichtbare Richtungszeichen (sonst könnten sie Terminals steuern oder andere Namen vortäuschen); die CLI filtert ihre Ausgabe zusätzlich und liest den Einladungslink aus der Eingabe statt aus der Kommandozeile.
- **Überlast:** höchstens 16 gleichzeitig laufende Handshakes, höchstens 6 Wartende ohne QR-Code (eine Namensänderung verlängert die Wartezeit nicht), am Relay höchstens 4 Räume pro Adresse; die Grenzen werden nach dem WebSocket-Upgrade erneut geprüft (sonst umgingen gleichzeitige Anfragen sie).
- **Weiter umgesetzt:** gefilterte Sichten (getestet für jeden Spieler), Identität nur aus der Sitzung, 128-Bit-Sitzungstokens im sicheren Speicher, strenges Parsen mit Größenlimits, Ratenlimits, Handshake- und Hello-Timeout, Verbindungslimit, LAN-Socket nur für private/Loopback-Adressen, strenge Prüfung des QR-Links mit Bestätigung vor dem Verbinden, Relay ohne Spielwissen (sieht nur Chiffretext), Container ohne Root und ohne Shell, Fuzz-Tests für Protokoll und Host.
- **Grenzen:**
  - Wer ohne QR-Code beitritt, ist bis zum Vergleich des Prüfbilds nicht authentisch. Danach bekommt er mit dem Welcome das Raumgeheimnis; ein Rejoin mit Token über einen nicht geprüften Kanal wird abgelehnt, und die App schickt ihr Token dort gar nicht erst.
  - Wer den Raumschlüssel stiehlt (er liegt bis zum Schließen des Raums im App-Ordner des Hosts), kann aufgezeichnete Verbindungen dieses Raums entschlüsseln; kein Forward Secrecy innerhalb eines Raums.
  - Die Komposition der libsodium-Bausteine ist unsere; ein externer Review steht noch aus (Pflicht vor den Stores, 0.1 bleibt Entwickler-Beta).
  - `dart:io`-WebSockets lesen eine Nachricht vollständig, bevor unsere Größenprüfung greift. Die Kompression ist überall abgeschaltet (sonst ließe ein kleiner Frame sich auf Gigabyte aufblähen); ein Angreifer muss jedes Byte also selbst senden, kann den Speicher aber weiterhin mit sehr großen Frames belasten (offen: eigene Rahmung oder Bibliothek mit Größenlimit, am Relay ein Größenlimit im Reverse Proxy).
  - Die Anzahl der Nachrichten eines Spielers an den Host ist nicht ausgeglichen (wer nachts mehr tippt, sendet mehr); Größen sind verborgen (der Host füllt jede Nachricht auf mindestens 8 KiB auf, alle Sichten sind gleich groß), Anzahlen nicht.
  - Unbekannte JSON-Felder werden derzeit ignoriert statt abgelehnt; der Raum-Schnappschuss (`room.json`) kann unter iOS ins Backup gelangen; der LAN-Socket lauscht auf allen Schnittstellen (nur private Absender werden angenommen).

## Offene Entscheidungen

- Größenstufen und Takt für das Padding in geheimen Phasen (M2).
- Prüfbild beim manuellen Beitritt: Symbole oder Zahlen (M3).
