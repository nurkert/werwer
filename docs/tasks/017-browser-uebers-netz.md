# Task 017 – Im Browser mitspielen, auch über das Internet

**Status:** geplant (2026-10-28)
**Bezug:** [ROADMAP](../ROADMAP.md) „Nach dem MVP“ Punkt 1 und 9, [SECURITY_DESIGN](../SECURITY_DESIGN.md) „Die Web-App vom Host“, Entscheidung vom 2026-10-26 „Beitritt im Browser im WLAN“

Heute kann man im Browser nur im selben WLAN mitspielen: Das Host-Handy liefert die Web-App selbst aus, und die Seite verbindet sich nur mit dem Gerät, von dem sie kam (`dialPageHost()`). Der Wunsch des Eigentümers: Wer per QR-Code mit der Handykamera beitritt, soll auch über mobile Daten mitspielen können. Die Oberfläche soll dabei sauber übers Netz kommen, entweder vom Server (opt-in) oder vom Host selbst.

## Ziel

- Ein Spieler ohne App scannt den QR-Code mit der Kamera und spielt im Browser mit, egal ob er im WLAN ist oder über mobile Daten.
- **Der Server liefert die Web-App aus, opt-in:** Ein eigener Schalter am Relay, auf `play.whowolf.de` an. Wer einen eigenen Server betreibt, entscheidet selbst.
- **Mehrere Versionen auf dem Server:** Unter `/v/<Protokollversion>/` liegt jede veröffentlichte Version. Der QR-Link des Hosts zeigt auf genau seine, damit Host und Browser nie aneinander vorbeireden.
- **Rückfall auf den Host:** Hat der Server die Version des Hosts nicht (eigener Server ohne Web-App, neue Version noch nicht ausgerollt), kommt die Oberfläche vom Host-Handy, durch das Relay getunnelt.
- Im WLAN ändert sich nichts: Die App verbindet sich weiter zuerst direkt, das Relay nur, wenn es sein muss.
- **Wer ausliefert, ist einstellbar:**
  - **Eigene Einstellungen (global, opt-out):** „Browser-Spielern die Oberfläche von meinem Gerät ausliefern“, Standard an. Wer es abschaltet, spart mobile Daten und Akku, denn jeder Browser-Spieler lädt etwa 5 MB.
  - **Lobby (nur Host, gilt nur für diese Runde):** „Oberfläche für den Browser kommt von“ *Automatisch* (Server, wenn er die Version hat, sonst dieses Gerät), *diesem Gerät* oder *dem Server*. Das überschreibt die globale Einstellung vorübergehend. Ist keine Quelle möglich, sagt die Lobby das, und der QR-Code ist dann nur für die App gedacht.
  - **Nur Host oder Server, keine Mitspieler:** Wer die Seite ausliefert, könnte mit einer veränderten App die geheime Rolle des Browser-Spielers lesen. Der Host kennt sie ohnehin, der Server spielt nicht mit. Ein Mitspieler als Lieferant wäre dagegen ein Schummelweg.
  - Die Wahl ist Sache des Host-Geräts und seines Transports, keine Spielregel. Sie gehört also weder in `GameSettings` noch ins Protokoll, sondern bleibt beim `HostedRoom` bzw. in den App-Einstellungen.

## Ablauf

1. Der Host öffnet einen Raum mit Relay. Beim Anmelden (`/host`) sagt das Relay, ob es die Web-App für die Protokollversion des Hosts ausliefert.
2. Der QR-Code zeigt dann, je nach Wahl in der Lobby:
   - **Server hat die Version:** `https://<server>/v/<pv>/join?room=…&relay=…&lan=…#k=…&s=…`
   - **Server hat sie nicht:** `https://<server>/r/<relayRoom>/join?…#k=…&s=…`. Das Relay holt jede Datei beim Host ab.
   - **Kein Relay:** wie heute `http://<Host-IP>/join?…`
3. Die App liest alle drei Formen und verbindet sich wie bisher: zuerst WLAN, nach 1,5 s das Relay.
4. Der Browser lädt die Seite und verbindet sich:
   - Kommt die Seite vom Host (`http://`), wählt sie den Host direkt an wie heute.
   - Kommt sie über `https://` vom Server, geht sie über `wss://<server>/join/<relayRoom>`. Ein direkter Weg ins WLAN ist von einer HTTPS-Seite aus nicht möglich, weil Browser `ws://` dort sperren (Mixed Content). Browser-Spieler über den Server laufen also immer über das Relay. Die Datenmenge ist klein.
5. Der Handshake (`secure_channel`) beweist wie immer, dass am anderen Ende der echte Host sitzt.

## Phasen

### Phase 1 – Browser über das Relay

- [ ] `web_join_screen.dart`: Der Browser wählt je nach Herkunft der Seite den Host direkt oder das Relay (`wss://`), mit demselben `connectSecure` und denselben Schlüsseln aus dem Fragment.
- [ ] Neuladen und Wiedereinstieg über `sessionStorage` funktionieren auch über das Relay.
- [ ] Test: Ein Browser-Client (Chrome in `tool/check.sh`) spielt über ein lokales Relay eine Partie mit dem Host.

### Phase 2 – Der Server liefert die Web-App aus (opt-in)

- [ ] Relay: Schalter `WEB_APP_DIR` bzw. `--web-app <Ordner>` (aus = heutiges Verhalten, nur WebSocket). Statische Auslieferung nur unter `/v/<pv>/…`, nur GET und HEAD, nur Dateien aus einer festen Liste (Manifest), keine Verzeichnislisten, keine Pfadtricks (`..`, `%2e`, doppelte Schrägstriche), gzip-Dateien wie auf dem Host.
- [ ] Release-Pipeline: Die Web-App jeder Version geht als Release-Datei `whowolf-<version>-webapp.tar.gz` mit Prüfsumme und Provenance raus.
- [ ] Docker-Image: `server/webapps.lock` listet je Protokollversion die neueste Web-App mit SHA-256. Der Image-Build lädt sie und prüft jede Prüfsumme. So hält das Image mehrere Versionen, und nichts Ungeprüftes kommt hinein.
- [ ] Antwort-Header: strenge `Content-Security-Policy` (nur `self` und `wss://<server>`), `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer`, kein Cache für `index.html`, lange Cache-Zeit für versionierte Dateien.
- [ ] Beim Anmelden des Hosts meldet das Relay, welche Protokollversionen es ausliefert. Der Host baut daraus den QR-Link.
- [ ] `play.whowolf.de`: Schalter an, Caddy unverändert (URI bleibt aus den Logs).

### Phase 3 – Rückfall: die Oberfläche vom Host durch das Relay

- [ ] Relay: `GET /r/<relayRoom>/<Pfad>` wird als Anfrage-Nachricht über die bestehende Host-Verbindung weitergereicht, die Antwort kommt in Stücken zurück. Nur Pfade aus dem Manifest des Hosts, harte Grenzen (Größe pro Datei, Bytes pro Raum und Minute, gleichzeitige Anfragen, Zeitlimit).
- [ ] Host: beantwortet diese Anfragen aus demselben `Site` wie im WLAN, ohne neuen Code-Pfad für die Dateien.
- [ ] Die Seite verbindet sich danach wie in Phase 1 über `wss://<server>/join/<relayRoom>`.
- [ ] Test: Ein Relay ohne Web-App liefert die Seite des Hosts aus, ein Browser spielt damit mit.

### Phase 4 – Einstellungen

- [ ] App-Einstellungen: Schalter „Browser-Spielern die Oberfläche von meinem Gerät ausliefern“ (Standard an), gespeichert wie die anderen Einstellungen in `Store`.
- [ ] Lobby des Hosts: Auswahl *Automatisch* / *dieses Gerät* / *Server*, vorbelegt aus der globalen Einstellung. Eine Änderung gilt nur für diesen Raum und baut den QR-Code sofort neu.
- [ ] *Server* ist nur wählbar, wenn das Relay verbunden ist und die Version des Hosts ausliefert. *Dieses Gerät* über das Netz nur mit Relay, im WLAN immer.
- [ ] Ist die Auslieferung durch das Gerät aus, liefert der Host im WLAN auch keine Seite mehr aus (der LAN-Server antwortet dann nur noch auf WebSockets), und das Relay verweigert `/r/<relayRoom>/…` für diesen Raum.
- [ ] Test: Mit abgeschalteter Auslieferung kommt keine Datei mehr vom Host, weder im WLAN noch über das Relay. Der QR-Code wechselt mit der Lobby-Wahl.

### Phase 5 – Abschluss

- [ ] SECURITY_DESIGN, Datenschutz (Website und App), Docs für Spieler und Server-Betreiber (`server/deploy/README.md`) ergänzen.
- [ ] Auf echten Geräten: iPhone als Host, ein Handy über mobile Daten im Browser, eines im WLAN im Browser.

## Sicherheit

**Was schiefgehen kann:**

- **Wer die Seite ausliefert, sieht die Schlüssel.** Die Schlüssel stehen im Fragment, das der Browser nie sendet, aber das JavaScript der Seite liest sie. Ein Server, der eine veränderte Web-App ausliefert, kann deshalb mitlesen und mitspielen. Das gilt für beide Wege, denn auch beim Rückfall (Phase 3) ist der Server der Ursprung der Seite. Spieler mit der App sind davon nicht betroffen.
- **Neue Angriffsfläche am Relay:** statische Dateien (Pfadtricks, Verzeichnislisten, große Dateien als Last) und HTTP-Weiterleitung zum Host (der Host als Lastquelle, offene Weiterleitung, Anfragen an fremde Räume).
- **Falsche Version:** Ein Browser mit anderer Protokollversion bekommt Nachrichten, die er nicht versteht.

**Was es verhindert:**

- Die Web-App ist **opt-in** am Server. Die App sagt beim Eintragen eines eigenen Servers schon heute, dass dessen Betreiber verantwortlich ist. Die Docs nennen dieses Vertrauen ausdrücklich: „Im Browser vertraust du dem Server, der die Seite ausliefert. Wer das ausschließen will, nimmt die App.“
- Auf `play.whowolf.de` kommt nur ausgeliefert, was die Release-Pipeline gebaut hat (Prüfsummen in `webapps.lock`, signiertes Image, Updates per Abruf und Signaturprüfung wie heute).
- Strenge CSP, keine Drittanbieter, kein Service Worker. Die Seite nimmt den Schlüssel nach dem Lesen aus Adresszeile und Verlauf (wie heute).
- Statische Auslieferung nur aus einem Manifest. Die Weiterleitung zum Host nur für offene Räume, nur Manifest-Pfade, mit Grenzen pro Raum und Adresse. Keine Header oder Cookies gehen weiter, das Relay schreibt keine Pfade ins Log.
- Die Version steckt im Pfad, und die Protokollprüfung (`protocolVersion`) lehnt Abweichungen wie bisher ab.

**Welche Tests es beweisen (blockieren den Merge):**

- Relay: Pfadtricks (`..`, `%2e%2e`, `//`, Backslash, Nullbyte), Dateien außerhalb des Manifests, POST/PUT, zu große Antworten, zu viele Anfragen und eine fremde `relayRoom` werden abgelehnt.
- Relay: Antwort-Header (CSP, `nosniff`, `no-referrer`) sind auf jeder ausgelieferten Seite gesetzt.
- Image-Build bricht ab, wenn eine Prüfsumme aus `webapps.lock` nicht stimmt.
- Browser über Relay: Ein Client mit falschem Schlüssel kommt nicht durch den Handshake, ein Client mit anderer Protokollversion wird abgewiesen.
