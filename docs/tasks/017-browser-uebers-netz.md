# Task 017 – Im Browser mitspielen, auch ohne WLAN

**Status:** geplant (2026-10-28), nach Review überarbeitet
**Bezug:** [ROADMAP](../ROADMAP.md) „Nach dem MVP“ Punkt 1 und 9, [SECURITY_DESIGN](../SECURITY_DESIGN.md) „Die Web-App vom Host“, Entscheidung vom 2026-10-26 „Beitritt im Browser im WLAN“

Heute kann man im Browser nur im selben WLAN mitspielen. Das Host-Handy liefert die Web-App selbst aus, und die Seite verbindet sich nur mit dem Gerät, von dem sie kam (`dialPageHost()`). Wer am Tisch sitzt, aber nicht ins WLAN kann oder will (Gäste-WLAN, Client-Isolation, kein Passwort), braucht bisher die App.

## Ziel und Grenzen

- **Für wen:** Leute, die **mit am Tisch sitzen**, aber nicht im WLAN sind. Sie scannen den QR-Code mit der Kamera und spielen im Browser über mobile Daten mit.
- **Ausdrücklich auch:**
  - Hotel- oder Gäste-WLAN, in dem sich die Geräte nicht gegenseitig erreichen (Client-Isolation).
  - Gar kein WLAN: Alle, auch der Host, sind über mobile Daten verbunden.

  In beiden Fällen läuft alles über das Relay. App-Spieler können das schon heute (das WLAN scheitert, nach 1,5 s übernimmt das Relay). Browser-Spieler können es mit diesem Task.
- **Die Falle dabei:** Ein `http://`-QR-Code im WLAN sieht für den Host gut aus, funktioniert bei Client-Isolation aber nicht. Deshalb nimmt *Automatisch* den Server, sobald er den Build hat, auch wenn der Host im WLAN ist. *Von diesem Handy* sagt dazu: „Nur, wenn sich die Handys im WLAN erreichen (nicht in vielen Hotel- und Gäste-WLANs).“
- **Nicht für Fernspieler:** Sitzkreis, Türzeichen, Wolfsspur und wandernder Erzähler setzen einen gemeinsamen Tisch voraus. Echtes Fernspiel wäre später ein eigenes Feature mit eigenen Regeln (Fernplatz ohne Sitz, ohne Türzeichen). Die Docs für Spieler sagen das so.
- **Ein Code:** Die Browser-Version ist dieselbe Flutter-App, für das Web gebaut (`tool/build_webapp.sh`). Unterschiede nur an den Rändern (Verbindung, Speicher, Ton freischalten, Wake Lock), keine eigene Browser-Oberfläche und keine Browser-Logik in den Bildschirmen.
- **Wer die Seite ausliefert:** über das Internet nur der **Server** (opt-in am Relay, auf `play.whowolf.de` an), im WLAN wie heute das **Host-Handy**. Keine Mitspieler, kein Tunnel vom Host durch das Relay (siehe Review unten).
- Mit der App ändert sich nichts: zuerst das WLAN, das Relay nur, wenn es sein muss.
- **Im Browser nur beitreten:** Ein Browser kann nie einen Raum öffnen. Die Web-App hat keinen Weg dahin, und das Relay lehnt `/host` ab, sobald ein `Origin`-Header dabei ist (den schicken Browser immer, die App nie). So kann auch keine fremde Webseite die Browser ihrer Besucher Räume öffnen lassen.
- **Viele Runden, viele Leute:** Das Relay trennt Räume und Spieler wie heute. Im Browser hat jeder Raum seinen eigenen Token, also kann ein Gerät auch in verschiedenen Runden sein, ohne dass sich etwas vermischt.
- **Keine Cookies, kein Banner:** Die Seite setzt keine Cookies, lädt keine Tracker und keine Drittanbieter. Gespeichert wird nur der Rückweg in die eigene Runde. Das ist für den gewünschten Dienst unbedingt nötig (§ 25 Abs. 2 TDDDG), braucht also keine Einwilligung. Stattdessen gibt es einen kurzen Hinweis nach Art. 13 DSGVO auf der Beitrittsseite, mit Link zur Datenschutzerklärung (wie in der App, Entscheidung vom 2026-10-26). Keine Rechtsberatung.
- **Ein QR-Code für alle:** Wer die App hat und mit der Kamera scannt, landet in der App am Tisch. Wer sie nicht hat, landet im Browser am selben Tisch. Dafür zeigt der QR-Code die Seite des Servers, und diese Adresse ist als Universal Link (iOS) bzw. App Link (Android) mit der App verknüpft. Mit dem Scanner in der App geht es weiter direkt, jetzt mit einer Überlagerung im Stil der Bühne.
- **Server nur bei Bedarf, ein QR-Code:** Im WLAN mit der App findet man den Raum ohne QR-Code (Bonjour, „Raum beitreten“). Der Server erfährt davon nichts. Den einen QR-Code gibt es erst, wenn der Host auf „QR-Code zeigen“ tippt. Erst dann öffnet sich der Raum auf dem Server, und der Code funktioniert für alle: mit der App (zuerst WLAN, sonst Server), mit der Kamera ohne App (Browser über den Server), im Hotel-WLAN und ohne WLAN. Ohne WLAN zeigt der Host den Code sofort. Für eine Runde ohne Internet bleibt unter „Verbindungsdetails“ der reine WLAN-Code (*von diesem Handy*). In den Einstellungen: *nur bei Bedarf* (Standard), *immer bereit* (Code sofort sichtbar), *nie* (heute „Nur WLAN“, nur der WLAN-Code).
- **Fehlertolerant:** Jeder Weg hat einen Rückfall. App: WLAN, dann Relay. Browser: Neuladen, zweiter Scan und neuer Tab führen zurück an den eigenen Platz. Fehlt der Host, sehen alle die ruhige Pause, und die Host-Übernahme greift wie heute.
- **Sicher für Betreiber und Spieler:** Jede neue Fläche am Server hat Grenzen pro Adresse, kein Log mit Pfaden oder Inhalten, und die Auslieferung ist opt-in.

## Ablauf

1. Der Host öffnet einen Raum mit Relay. Beim Anmelden (`/host`) sagt das Relay, welche Builds der Web-App es ausliefert.
2. Der QR-Code zeigt:
   - **Server hat den Build des Hosts:** `https://<server>/v/<pv>/<build>/join?room=…&relay=…&lan=…#k=…&s=…`
   - **Sonst, oder wenn der Host *dieses Handy* wählt:** wie heute `http://<Host-IP>/join?…` (nur im WLAN).
   - **Weder noch:** der Link für die App. Die Lobby sagt dann in einer Zeile: „Ohne App kann gerade nur jemand im selben WLAN beitreten.“ bzw. „… niemand beitreten.“
3. Der QR-Code wechselt nie von selbst, während die Lobby offen ist. Nur eine Wahl des Hosts oder der Verlust des Relays ändert ihn. Alte Links bleiben gültig, solange der Raum lebt.
4. Die App liest alle Formen und verbindet sich wie bisher.
5. Der Browser verbindet sich mit dem Ursprung, von dem die Seite kam:
   - Seite vom Host (`http://`): direkt, wie heute.
   - Seite vom Server (`https://`): nur `wss://<derselbe Server>/join/<relayRoom>`. Der Parameter `srv` im Link wird im Browser ignoriert. Ein direkter Weg ins WLAN ist von einer HTTPS-Seite aus nicht möglich (Mixed Content), deshalb laufen diese Spieler immer über das Relay.
6. Der Handshake (`secure_channel`) beweist wie immer, dass am anderen Ende der echte Host sitzt.

## Einstellungen

Möglichst wenig sichtbar, alles Weitere automatisch:

- **App-Einstellungen › Online-Spiel (global, opt-out):** „Browser-Spieler im WLAN laden die Seite von meinem Handy“, Standard an. Über das Internet liefert das Handy ohnehin nie aus, es kostet also keine mobilen Daten.
- **Lobby, unter „Verbindungsdetails“ (nur Host, nur diese Runde):** eine Zeile mit dem aktuellen Stand, zum Beispiel „Ohne App laden Mitspieler die Seite von play.whowolf.de. *Ändern*“. Auswahl:
  - *Automatisch:* Server, wenn er den Build hat, sonst dieses Handy im WLAN.
  - *Vom Server:* klappt auch ohne WLAN.
  - *Von diesem Handy:* nur im WLAN, klappt auch ohne Internet.

  Die Auswahl ist mit der globalen Einstellung vorbelegt.
- Die Wahl ist keine Spielregel. Sie kommt nicht in `GameSettings` und nicht ins Protokoll, sondern bleibt beim `HostedRoom` und in `Store`.

## Phasen

### Phase 1 – Browser über das Relay

- [x] `web_join_screen.dart` / `browser_socket.dart`: Der Browser wählt den Weg nach dem Ursprung der Seite, mit demselben `connectSecure` und denselben Schlüsseln aus dem Fragment.
- [x] `forgetPageLink()` behält den Basispfad (heute fest `/join`, unter `/v/…/` würde ein Neuladen ins Leere führen). Gemerkt wird die Form relativ zum Ursprung.
- [x] **Wiedereinstieg:** Token pro Raum in `localStorage` mit Ablaufzeit statt nur `sessionStorage`. Ein neuer Tab oder ein erneutes Scannen fragt „Weiter als {Name}?“ statt einen zweiten Platz anzulegen. Am Spielende gelöscht.
- [x] **Ton:** Hinsetzen braucht im Browser immer einen Tipp, auch beim Zurückkommen („Weiter als …“). Dieser Tipp spielt den Bedienklang und schaltet damit Audio frei (Autoplay-Sperre). Gähnen und Nachtgeräusche laufen über denselben Code wie in der App zum gemeinsamen Zeitpunkt. Auf echten Geräten (iOS Safari) zu prüfen, siehe Phase 4.
- [x] **Bildschirm an:** `wakelock_plus` nutzt im Browser die Screen Wake Lock API und fordert sie nach jedem Zurückkehren neu an (Browser geben sie frei, sobald die Seite verdeckt war). Auf der Beitrittsseite steht zusätzlich „Lass den Bildschirm an und den Ton laut, solange ihr spielt.“
- [x] **Pausen:** Fehlt der Host (iOS im Hintergrund), sieht der Browser die ruhige Pause wie in der App, nicht „Verbindung weg“. Das ist derselbe Code (`PlayerLink`, `GameScreen`), es gibt keine eigene Browser-Logik.
- [x] Test: Ein Browser-Client (Chrome in `tool/check.sh`) setzt sich über ein lokales Relay an den Tisch des Hosts und kommt nach dem Neuladen an denselben Platz zurück (`server/test/browser_relay_test.dart`, echter WebSocket im Browser, Relay und Host in der VM).

### Phase 2 – Der Server liefert die Web-App aus (opt-in)

- [x] Relay: `WEB_APP_DIR` bzw. `--web-app <Ordner>` (aus = heutiges Verhalten). Auslieferung nur unter `/v/<pv>/<build>/…`, nur GET und HEAD, nur Dateien aus dem Manifest des Builds, Medientyp aus einer festen Liste am Relay, keine Verzeichnislisten, keine Pfadtricks.
- [x] Antwort-Header auf jeder Datei, gemeinsam für Host und Server (`webAppHeaders` in `protocol`): `Content-Security-Policy` mit `default-src 'self'`, `connect-src 'self'` plus `wss://<PUBLIC_HOST>`, `object-src 'none'`, `base-uri 'none'`, `form-action 'none'`, `frame-ancestors 'none'`, dazu was CanvasKit braucht (`'wasm-unsafe-eval'`, `worker-src 'self' blob:`); `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer`, `X-Frame-Options: DENY`. Service Worker sind ausgeschlossen, weil das Relay jede Anfrage mit `Service-Worker`-Header ablehnt. `index.html` ohne Cache, die übrigen Dateien `immutable` (der Build steht im Pfad), ETag und `304`.
- [x] Statische Seiten vor Flutter: `index.html` zeigt beim Laden „Whowolf lädt … (ca. 5 MB)“ in reinem HTML (zweisprachig, `role="status"`). Für einen unbekannten Build liefert das Relay eine kleine Seite mit Text statt eines weißen Bildschirms. Dass eine Runde nicht mehr offen ist, zeigt die App selbst (ruhige Pause, dann Ende).
- [x] **Schlank im Betrieb:** Dateien liegen vorkomprimiert (gzip) im Image und werden beim Start einmal mit Manifest, Größe und ETag in den Speicher gelesen. Ausgeliefert wird ohne Komprimieren zur Laufzeit, ohne Dateisystemzugriff pro Anfrage, mit `304` auf `If-None-Match`. Versionierte Dateien haben `Cache-Control: public, max-age=31536000, immutable`, `index.html` `no-cache`. Keine Datenbank, kein Zustand auf der Platte, Speicherbedarf pro Build vorab bekannt (Log beim Start: Builds und Größe). TLS, HTTP/2 und Komprimierung im Transport macht wie heute Caddy.
- [x] Grenzen pro Adresse auch für HTTP (heute zählen nur WebSocket-Upgrades). Das Relay schreibt keine Pfade ins Log.
- [x] Relay: `/host` mit `Origin`-Header wird abgelehnt (Browser können keinen Raum öffnen).
- [x] Beitrittsseite: Hinweis nach Art. 13 DSGVO in einer Zeile mit Link zur Datenschutzerklärung, offline in der Web-App (wie in der App).
- [x] Release-Pipeline: Web-App jedes Releases als `whowolf-<version>-webapp.tar.gz` (`tool/package_webapp.sh`, reproduzierbar), mit Prüfsumme in `SHA256SUMS.txt` und Attestation wie alle Release-Dateien.
- [x] `server/webapps.lock`: nur anhängen (`tool/check_webapps_lock.sh` in `tool/check.sh`), ein Eintrag je Build mit SHA-256, Rückzug per `retire`. `tool/fetch_webapps.sh` bricht bei falscher Prüfsumme ab, ohne etwas zu entpacken, und überspringt zurückgezogene Builds (`tool/test_fetch_webapps.sh` in `tool/check.sh`, offline).
- [x] Image-Build: Der Relay-Job ist so verdrahtet, dass er nach dem Release läuft, jeden Build aus `webapps.lock` und den des laufenden Releases mit `tool/fetch_webapps.sh` holt und unter `/webapps` ins Image legt. Das Skript ruft für jeden Build `gh attestation verify --signer-workflow …/prerelease.yml` auf. Ausgeführt wird dieser Weg erst im Release (siehe Phase 4). Im Release 0.2.0 grün durchgelaufen (Run 40780247256), play.whowolf.de liefert `/v/15/0.2.0/join`.
- [x] Die App versteht die neuen Links (`/v/…/join` nur zusammen mit dem Schlüssel, `JoinLink.tryParse`, auch im Scanner). Eingehende Links nimmt sie mit Flutters eingebautem Deep Linking an (`app/lib/src/net/app_links.dart`), ohne neue Abhängigkeit: nur Seiten des offiziellen Servers mit Schlüssel, und immer mit derselben Frage wie nach einem Scan. Dabei gefunden: Ohne `onGenerateRoute` baut `MaterialApp` keinen Navigator, die App bliebe mit einer Startroute leer (Test `app/test/app_links_test.dart`).
- [x] **Ein QR-Code für alle:** Das Relay liefert `/.well-known/apple-app-site-association` und `/.well-known/assetlinks.json` nur, wenn `APPLE_APP_ID` bzw. `ANDROID_CERT_SHA256` gesetzt sind; nichts davon steht im Repo. Android: `intent-filter` mit `autoVerify` für `https://play.whowolf.de/v/*/join`. iOS **zum Einschalten**: `app/ios/Runner/AppLinks.entitlements` liegt bereit und wird mit einer Zeile `CODE_SIGN_ENTITLEMENTS = Runner/AppLinks.entitlements` in der git-ignorierten `ios/Flutter/Signing.xcconfig` aktiv. Ohne bezahlten Account baut die App also wie bisher (Wunsch des Eigentümers).
- [x] `whowolf.de/join` ohne passende Quelle: Die Seite gibt es schon (`website/src/components/pages/Join.astro`). Wer den reinen App-Code mit der Kamera scannt, liest dort „Mitspielen geht mit der App“, sieht die drei Schritte und kommt zum Download.

### Phase 3 – Einstellungen und Lobby

- [x] Einstellungen › Online-Spiel: Server *nur bei Bedarf / immer bereit / nie* und der Schalter „Browser-Spieler im WLAN laden die Seite von meinem Handy“. Die Wahl pro Runde ist in der Einladung: „QR-Code zeigen“ (Server) oder „Nur WLAN-Code, ohne Server“, letzteres auch unter „Verbindungsdetails“, solange der Server-Code gezeigt wird.
- [x] **Server nur bei Bedarf:** `HostedRoom.open(online: …)` öffnet das Relay sofort nur mit *immer bereit* oder ohne private Adresse, sonst erst bei `goOnline()`. Die Einladung des Hosts zeigt zuerst „Im selben WLAN? … Raum beitreten“ und den Knopf „QR-Code zeigen“. Erst der Knopf öffnet den Raum auf dem Server und zeigt den einen Code (Seite des Servers, wenn er den Build hat, per `HEAD` geprüft). Daneben „Nur WLAN-Code, ohne Server“. Die Einstellung *nur bei Bedarf / immer bereit / nie* ersetzt den Schalter „Nur WLAN“ (alter Wert wird als *nie* gelesen). Wiederherstellen nach einem Absturz und Host-Übernahme öffnen das Relay wie bisher, sobald ein Server eingestellt ist (seltene Fälle, dokumentiert).
- [x] Test: Die Regel „Server nur bei Bedarf“ steckt in `OnDemandRelay`, das `HostedRoom` benutzt, und läuft in der CI (`app/test/on_demand_relay_test.dart`): im WLAN nicht sofort, ohne WLAN oder mit *immer bereit* sofort, der Server-Raum öffnet sich genau einmal, auch bei einem Doppeltipp (dabei gefunden und behoben: zwei schnelle Tipps hätten zwei Räume geöffnet), ein Fehlversuch darf wiederholt werden.
- [x] **Scanner im Stil der Bühne:** Kamerabild hinter dunkler Bühnennacht, eine Öffnung mit Messingrahmen und Laternen-Ecken, Titel in der Bühnenschrift und ein Hinweis darüber, Taschenlampe oben rechts, fremde Codes auf einem Papierschild darunter (`app/lib/src/scan_screen.dart`). Am Gerät anzusehen, siehe Phase 4.
- [x] Der Einladungstext richtet sich danach, ob der Browser möglich ist (`HostedRoom.browserCanJoin`), nicht mehr nach dem Schema des Links.
- [x] Am Platz eines Browser-Spielers steht in der Lobby „im Browser“, **nur in der Lobby**, nie nachts (das hängt nicht an der Rolle, verrät also nichts). Dafür **Protokoll Version 8**: `Hello.web` und `StateMessage.inBrowser`, das der Host nur in der Lobby füllt (Tests in `protocol_test.dart` und `host_test.dart`).
- [x] Test: Mit abgeschalteter Auslieferung gibt der Host im WLAN keine Datei heraus, weder per `GET` noch per `HEAD` (`packages/game_host/test/site_test.dart`). Der QR-Code folgt der Wahl: Server-Seite, WLAN-Code oder nur App-Link (`app/test/invite_code_test.dart`, Entscheidung in `inviteCode`).

### Phase 4 – Abschluss

- [x] SECURITY_DESIGN (neuer Abschnitt „Die Web-App vom Server“), Datenschutz in App und Website (Server nur bei Bedarf, Auslieferung der Seite, Speicher im Browser), Betreiber-Doku und `docker-compose.yml` (`server/deploy/README.md`: `WEB_APP_DIR`, Speichergrenze, App-Links aus `domain.env`).
- [x] Docs für Spieler auf whowolf.de: Mindestanforderungen im Browser (aktueller Browser, Ton an, Bildschirm an) und „am Tisch, nicht aus der Ferne“. Steht im Kapitel „Was ihr braucht“ (`website/src/content/guide/*/need.md`), das dabei auch den alten Satz „Browser geht noch nicht“ und die Servereinstellung berichtigt hat.
- [x] Integrationstest „Server nur bei Bedarf“ mit echtem `HostedRoom` und Zähl-Relay ausführen (`app/integration_test/table_test.dart`, geschrieben, hier nicht lauffähig: Dem Linux-Build fehlt das Systempaket `gstreamer-1.0`). Am 2026-10-29 auf macOS ausgeführt: alle sechs Tests grün (`flutter test integration_test/table_test.dart -d macos`). Drei waren veraltet und sind ans heutige Spiel angepasst (Lobby mit Seiten, Einladung hinter „Mitspieler einladen“, Figur zum Aufdecken, klassische Nacht als Standard, Wiederherstellen nur mitten im Spiel); dabei fiel der Überlauf der Prüfzeichen beim Reinlassen auf und ist behoben.
- [x] Erstes Release nach Task 017 beobachten: `tool/fetch_webapps.sh` mit `gh attestation verify` und `tool/verify_webapp.sh` laufen dort zum ersten Mal in der CI (hier gibt es weder `gh` noch einen GitHub-Zugang). Im Release 0.2.0 liefen beide grün: `verify_webapp.sh` im Linux-Build, `fetch_webapps.sh` mit `gh attestation verify` im Relay-Job.
- [ ] **Voraussetzungen beim Eigentümer:** Universal Links unter iOS brauchen den Apple Developer Account (fehlt noch, siehe 2026-10-26). App Links unter Android brauchen den Release-Schlüssel (Vorabversionen sind mit dem Debug-Schlüssel signiert). Bis dahin öffnet der QR-Code mit der Kamera immer den Browser, und mit dem Scanner in der App geht es wie heute.
- [ ] Auf echten Geräten: iPhone als Host; iOS Safari und Android Chrome über mobile Daten im Browser, eines im WLAN im Browser. Ton, Wake Lock, Neuladen, Host kurz im Hintergrund.

## Sicherheit

**Was schiefgehen kann:**

- **Wer die Seite ausliefert, sieht die Schlüssel** (das JavaScript liest das Fragment). Ein Server mit veränderter Web-App könnte mitlesen und mitspielen. Spieler mit der App sind nicht betroffen.
- **Statische Dateien am Relay:** Pfadtricks, Verzeichnislisten, Last durch große Dateien, alte Builds mit Lücken, die ewig ausgeliefert werden.
- **Lieferkette:** eine manipulierte Release-Datei oder ein falscher Eintrag in `webapps.lock`.
- **Gemischte Builds:** Ein Release mitten in der Runde mischt beim Neuladen alte und neue Dateien.
- **Metadaten:** Das Relay sieht Größe und Zeitpunkt jeder Nachricht. Browser-Spieler laufen über das Internet immer über das Relay.
- **Datenschutz:** Wer scannt, zeigt dem Betreiber Adresse und User-Agent, auch ohne beizutreten.

**Was es verhindert:**

- Auslieferung **opt-in** am Server. Die App sagt beim Eintragen eines eigenen Servers schon heute, dass dessen Betreiber verantwortlich ist. Die Beitrittsseite sagt in einer Zeile: „Im Browser vertraust du dem Server, der diese Seite liefert. Mit der App nicht.“
- Auf `play.whowolf.de` nur Builds aus der Release-Pipeline: Attestation geprüft, Prüfsumme gepinnt, signiertes Image, Updates per Abruf wie heute.
- **Ein Ursprung, nur Builds aus der Pipeline:** Kein Host und kein Mitspieler kann Code auf dem Ursprung des Servers ausführen. Damit kann auch keine Seite Speicher oder Service Worker für andere Runden hinterlassen. Dafür ist der Tunnel vom Host gestrichen.
- Strenge CSP ohne Service Worker und Drittanbieter. Der Browser verbindet sich nur mit seinem eigenen Ursprung. Der Schlüssel verschwindet nach dem Lesen aus Adresszeile und Verlauf.
- Build-ID im Pfad. Die Protokollprüfung (`protocolVersion`) lehnt Abweichungen ab.
- Bekannte Grenze, dokumentiert: QR-Link und Screenshots davon sind der Raumschlüssel. Nachrichtengrößen zu vereinheitlichen ist ein eigener späterer Schritt und betrifft auch App-Spieler über das Relay.

**Welche Tests es beweisen (blockieren den Merge):**

- Relay: Pfadtricks (`..`, `%2e%2e`, `//`, Backslash, Nullbyte), Dateien außerhalb des Manifests, unbekannter Build, POST/PUT, zu viele Anfragen pro Adresse werden abgelehnt. Ist die Auslieferung aus, antwortet auch `HEAD` mit 404. Kein Pfad im Log.
- Relay: `/host` mit `Origin`-Header wird abgelehnt, ohne angenommen.
- Datenschutz: Ein Raum im WLAN mit *nur bei Bedarf* öffnet keine Verbindung zum Server, bis der Host es will, und dann genau eine (`app/test/on_demand_relay_test.dart` in der CI; mit echtem Raum und Zähl-Relay in `app/integration_test/table_test.dart`, Phase 4).
- Relay: CSP und die übrigen Header stehen auf jeder Datei (`server/test/web_apps_test.dart`). Vor jedem Release startet `tool/verify_webapp.sh` den gepackten Build vom Relay in Headless-Chrome **unter genau diesen Headern**: Flutter muss starten, und der Browser darf nichts verweigern außer dem absichtlich gesperrten `<base>`. Am 2026-10-28 lokal mit Chromium bestanden.
- `tool/fetch_webapps.sh` bricht bei falscher Prüfsumme ab und entpackt nichts, zurückgezogene Builds bleiben draußen (`tool/test_fetch_webapps.sh`). `webapps.lock` wird nur ergänzt, nie geändert (`tool/check_webapps_lock.sh`). Beides in `tool/check.sh`.
- Über das Relay kommt ein Client mit falschem Schlüssel oder falschem Raumgeheimnis nicht durch den Handshake, der richtige bekommt einen Platz (`packages/secure_channel/test/relay_handshake_test.dart`; dabei gefunden und behoben: Das Relay warf beim Herunterfahren eine ungefangene Ausnahme, weil es auf einen schon geschlossenen Socket schrieb). Eine Seite mit anderer Protokollversion wird im echten Browser nicht an den Tisch gesetzt (`server/test/browser_relay_test.dart`). Neuladen unter `/v/…/` behält den Pfad, nimmt den Schlüssel aus der Adresse und findet den Platz wieder, ein anderer Raum mischt sich nicht ein (`app/test/browser/browser_socket_test.dart`, in Chrome). Die Kryptografie im Browser selbst (sodium.js) ist derselbe Dart-Code wie in der App; sie im Browser gegen einen Host laufen zu lassen, bleibt der Test auf echten Geräten (Phase 4).
- App: Parser-Tests für die neuen Linkformen, kein HTTPS-Link ohne Schlüssel.
- App: Ein eingehender Link (Deep Link) mit fremdem Host, ohne Schlüssel oder mit falschem Pfad wird ignoriert, ein gültiger führt zur selben Bestätigung wie ein Scan.
- Relay: Die `.well-known`-Dateien gibt es nur bei gesetzter Konfiguration, mit festem Medientyp und ohne Werte aus der Anfrage.

## Review (2026-10-28)

Der Plan wurde unabhängig aus drei Richtungen geprüft: Sicherheit, Bedienung, Spieldesign. Codex und Antigravity konnten nicht laufen (Sandbox bzw. fehlender Login). Eingearbeitet:

- **Gestrichen: Seite vom Host durch das Relay** (`/r/<raum>/`). Fremder Code auf dem Ursprung des Servers hätte Speicher und Service Worker für andere Runden hinterlassen können. Neuladen hätte das Byte-Budget des Hosts gesprengt und die Runde beendet (4 MB auf einmal). Dazu viele MB über die mobilen Daten des Hosts. Ersatz: Der Server hat den aktuellen Build als Pflicht im Release, sonst gilt Browser nur im WLAN.
- **Zielgruppe** auf „am Tisch, ohne WLAN“ festgelegt. Fernspieler würden Türzeichen, Sitzkreis und Wolfsspur aushebeln.
- Lobby-Auswahl unter „Verbindungsdetails“ statt sichtbar. Der Opt-out schaltet das Browser-Spiel im WLAN nicht mehr ungewollt mit ab. Der QR-Code wechselt nicht von selbst.
- Build-ID im Pfad, Attestation vor `webapps.lock`, Grenzen auch für HTTP, Basispfad beim Neuladen, Einladungstext nach Möglichkeit statt Schema, Wiedereinstieg per Token pro Raum, Ton freischalten und Wake Lock als Abnahmekriterium (sonst hätte ein Wolf eine Ausrede gegen den Gähn-Check), statische Lade- und Fehlerseiten.
