# Task 021 – Nahtlos weiterspielen: Fehlertoleranz nach Lehrbuch

**Status:** in Arbeit (2026-10-28). Freigegeben vom Eigentümer: Schritte 1–4 vollständig; Sicherheit nur gegen Störer, die nicht mitspielen (Server und Nutzer dürfen nie Schlimmeres erleiden als ein abgebrochenes Spiel). Schritte 1 bis 4 erledigt.
**Bezug:** [ARCHITECTURE](../ARCHITECTURE.md), [SECURITY_DESIGN](../SECURITY_DESIGN.md), Task 002 (stabiles Netz), Task 008 (Host-Übernahme), Task 020 (Spielabend)

## Ziel

Wer einmal angefangen hat, spielt bis zum Ende, auch wenn das WLAN hakt, ein Handy kurz weg ist, jemand geht oder der Host ausfällt. Kurze Unterbrechungen merkt am Tisch niemand. Übergänge sind **vorher vereinbart**: Ein Gerät, das einen Befehl verpasst, schaltet trotzdem pünktlich um und hängt nie hinterher.

Grundlage sind zwei Vorlesungen des Eigentümers (Uni Ulm): *Fault-tolerant Distributed Systems* (Primary-Backup, Leases, Epochen, Failure Detectors, Chaos-Tests) und *Security and Privacy in Mobile Systems* (Pairing über einen Zweitkanal, Sybil, Rogue Host, Seitenkanäle). Aus der MANET-Vorlesung passt Routing **nicht**: Whowolf ist ein Stern um den Host mit einem Sprung, kein Multi-Hop-Netz.

## Grundprinzip: alles wird vorher vereinbart

Wunsch des Eigentümers (2026-10-28): nicht nur Sprecher-Einsätze, **alles** wird unter den Geräten vorher vereinbart. Jeder Übergang, jeder gemeinsame Klang und jeder Satz des Erzählers hat einen Zeitpunkt in Host-Zeit, den alle Geräte vorher kennen.

- **Vereinbart heißt bestätigt:** Der Host weiß, welches Gerät welchen Plan hat (es bestätigt die Version). Wer nicht bestätigt, bekommt keinen Einsatz; ein Gerät, das stumm ist oder weg, wird ersetzt, und der Rest des Plans richtet sich neu aus.
- **Dynamisch:** Ein Plan hat ein spätestes Ende (die Hexe schläft spätestens nach ihrer Zeit wieder ein). Entscheidet sie früher, kommt der neue Plan früher; auch dann schalten alle zum selben Zeitpunkt um.
- **Verpasst ist verpasst:** Ein Gerät, das einen Einsatz zu spät erfährt, spricht ihn nicht nach, sondern steigt im laufenden Plan ein. Es weiß, dass es nichts mehr sagen muss.
- **Niemand nimmt etwas an, was nicht passiert ist:** Ein stummes oder fehlendes Gerät gilt nie als gesprochen; der Plan zeigt, wer wirklich dran war.

## Fehlermodell (neu, ausdrücklich)

- **Host:** Crash-Recovery, nicht byzantinisch (ein manipulierter Host liegt außerhalb des Modells; Gegenmittel ist die soziale Kontrolle am Tisch).
- **Clients:** dürfen alles senden; der Host prüft jede Absicht (wie heute).
- **Kanäle:** verlieren, verzögern, verdoppeln, vertauschen; Wiederholung + Sequenznummer + Deduplizierung machen daraus einen verlässlichen Kanal.
- **Partitionen:** möglich (Gast-WLAN mit Client-Isolation, Relay weg). Dann gilt: lieber kurz einfrieren als zwei Spiele (CP statt AP).

## Was es schon gibt (gut, bleibt)

Sequenzierte, idempotente Absichten mit Ack (`host.dart` `_receive`), Snapshot vor jedem Ack, Push-Pull-Abgleich der Sichten über Version und Ping, Uhrabgleich nach NTP-Prinzip (`ClockSync`), Host-Übernahme mit versiegeltem Stand beim Nachfolger, Zeuge und Epoche (Task 008), Chaos-Test in virtueller Zeit (`chaos_test.dart`).

## Schritte (nach Wirkung geordnet)

### 1. Keine bestätigte Aktion geht bei einer Übernahme verloren

**Befund (im Code geprüft):** Der Host bestätigt nach dem lokalen Snapshot, versiegelt den Stand für den Nachfolger aber erst danach und asynchron (`_reseal`). Der Client verwirft bestätigte Absichten (`player_link.dart` `_welcomed`). Stirbt der Host dazwischen, ist z. B. die Stimme oder die Wahl der Seherin weg (Lost-Progress-Gap).

- Der Client behält bestätigte Absichten der laufenden Epoche, bis eine Sicht mit höherer Epoche sie enthält; bei `Welcome` einer höheren Epoche schickt er alle mit `seq > lastSeq` erneut. Die Sequenzprüfung macht das sicher.
- Test in `takeover_test.dart`: Absicht bestätigt, Host stirbt vor dem Versiegeln, nach der Übernahme wirkt sie.
- **Dabei gefunden und behoben:** Der neue Host zählt die Versionen von seiner (älteren) Kopie weiter; die Geräte verwarfen seine Zustände, solange die Nummer kleiner war als die zuletzt gesehene, und zeigten so ein Spiel, das es nicht mehr gab. Jetzt zählt die Version je Epoche (Test: die Runde geht beim alten Host in die Nacht, die Kopie ist noch in der Rollenvergabe, alle zeigen danach den Stand des neuen Hosts).
- Abweisungen, die nur erneut gesendete Absichten betreffen, sieht der Spieler nicht.
- **Erledigt (2026-10-28).**

### 2. Zeitpunkte absolut in Host-Zeit

**Befund:** `phaseEndsInMs` ist relativ; der Client rechnet ohne Laufzeit und ohne Uhrabgleich, der Snapshot speichert die Restzeit. Nach einer Übernahme verlängert sich die Phase um die Ausfallzeit.

- `StateMessage` trägt `phaseEndsAt` in Host-Zeit (wie schon `phaseAt`), Anzeige über `ClockSync.toLocal`.
- Der Snapshot speichert die Deadline absolut; der Nachfolger übernimmt sie über seinen Uhrabgleich zum alten Host. Die Phase endet wie geplant, ist sie schon vorbei, sofort.
- Sichten werden über **(Epoche, Version)** verglichen, nie über die Version allein (mit Schritt 1 erledigt).
- Eine Pause des Spielleiters bleibt über Neustart und Übernahme bestehen (vorher lief die Uhr danach einfach weiter).
- Der Uhrabgleich bleibt beim Wiederverbinden mit demselben Host erhalten; neu gemessen wird nur bei einem neuen Host. So stimmen Zeiten nach einem kurzen Aussetzer sofort.
- Ein Ende, das während eines Ausfalls verstrichen ist, kommt `GameHost.restoreGrace` (2 s) nach der Rückkehr, damit alle wieder da sind.
- **Erledigt (2026-10-28), Protokoll Version 13** (`StateMessage.phaseEndsAt`). Tests: `takeover_test.dart` (Ende und Beginn bleiben über die Übernahme, Pause bleibt), `host_test.dart` (Neustart hält das vereinbarte Ende).

### 3. Übergänge vorher vereinbaren

- Kurz vor dem Ende eines Schritts (T − Δ, Δ etwa 1,5 s) schließt der Host die Eingaben, rechnet den Übergang aus, speichert und versiegelt ihn für den Nachfolger und schickt jedem Gerät **seine nächste gefilterte Sicht mit `showAt = T`**.
- Jedes Gerät schaltet zum Zeitpunkt T selbst um, auch ohne Verbindung in diesem Augenblick. Gilt nur innerhalb der Epoche; eine neue Epoche ersetzt vorgemerkte Sichten.
- Absichten nach dem Eingabeschluss bekommen eine klare Antwort („zu spät“), nie Schweigen.
- Wo es den Spielablauf nicht verändert (Ende von Diskussion, Nachtschritt, Abstimmung nach Zeit): ja. Vorzeitige Enden („alle haben gestimmt“) laufen weiter sofort, mit `showAt` = jetzt + kleiner Puffer, damit alle gleichzeitig umschalten.

**Umgesetzt (2026-10-28), Protokoll Version 14:**
- Jeder Phasen- oder Schrittwechsel wird beschlossen und mit `showAt` = jetzt + `HostConfig.switchLead` (1,2 s) verteilt; die neue Phase zählt ihre Zeit ab dann, Erzähler und gemeinsame Klänge hängen am selben Zeitpunkt (`phaseAt` = `showAt`). Zeit- und Absichts-Enden laufen gleich, die Hexe, die früher entscheidet, verschiebt nur den Zeitpunkt.
- `PlayerLink` hält einen angekündigten Stand und zeigt ihn zum vereinbarten Zeitpunkt, auch wenn die Verbindung dazwischen abreißt. Ein Gerät, das ihn zu spät bekommt, zeigt ihn sofort und steigt mitten im Plan ein; Sätze, deren Zeit vorbei ist, sagt es nicht nach.
- Abweisungen für Tipps auf den Schritt, der gerade endet, sieht der Spieler nicht.
- **Stimmen mit Lebenszeichen:** Der Host führt `voices` (verbunden, in den letzten 7 s gehört, nicht stumm) und schickt jede Änderung sofort, auch mitten in der Nacht. Ohne eigenen Timer: jede eingehende Nachricht (alle Geräte pingen alle 3 s) prüft die Liste. Alle Geräte planen Erzähler und gemeinsame Klänge über diese Liste; fällt ein Gerät aus oder wird stumm, geht der Rest des Plans an die anderen, der laufende Satz endet, wo er läuft.
- Tests: `host_test.dart` (Ankündigung und Zeit ab dem Zeigen; Stimmen folgen Stummschalten, Schweigen, Rückkehr, Abbruch), `player_link_test.dart` (Umschalten zum vereinbarten Zeitpunkt trotz Abbruch), `walking_narrator_test.dart` (Ausfall mitten im Satz).

### 4. Nie zwei Hosts: Leader-Lease

**Befund:** Bei einer Partition übernimmt der Nachfolger, während der alte Host mit seinen Spielern weiterschaltet (Split Brain).

- Der Host schaltet Phasen nur weiter und bestätigt nur, solange er in den letzten 4 s (unter der Übernahmeschwelle von 6 s) von Nachfolger **oder** Zeuge gehört hat. Sonst friert er ein und zeigt die Pause.
- Kleine Tische ohne Nachfolger und Zeuge: keine Lease, wie heute.
- Test: Host partitioniert, kommt nach 20 s zurück; es gab nie zwei weiterschaltende Hosts, alle landen beim Gewinner.

**Umgesetzt (2026-10-28), Protokoll Version 15:**
- Nachfolger und Zeuge pingen jede Sekunde (`LinkConfig.holderPing`); der Host bewegt das Spiel nur, solange er einen der beiden in `HostConfig.leaseTime` (4 s, unter der Übernahmeschwelle von 6 s) gehört hat. Als Paar kommen nur Geräte in Frage, die er in dieser Zeit gehört hat.
- **Host abgeschnitten** (hört außer seinem eigenen Spieler niemanden): Er friert ein (`GameHost.frozen`). Keine Phase läuft ab, keine Absicht wird angewendet oder bestätigt; die Geräte behalten sie und geben sie dem, der hostet (Schritt 1). Kommt einer des Paars zurück, ohne übernommen zu haben, vergisst er seinen Teil und es geht weiter. Ein Gerät, das schon einen neueren Host gesehen hat, wird nicht mehr aufgenommen und zählt nicht als zurück.
- **Nur das Paar ist weg**, der Rest des Tischs noch da: Der Host beansprucht den Raum neu, **zwei Epochen weiter** (über allem, was das Paar daraus machen kann), wählt ein neues Paar und kündigt sich neu an (`GameHost.onEpoch`). Die Geräte übernehmen die Epoche aus dem Zustand (`StateMessage.epoch`). Ein Raum, den das Paar unter sich übernommen hat, hat die kleinere Epoche und gibt nach, sobald man sich wieder trifft.
- Bewusst nicht: ein später Neuanspruch. Wer eingefroren ist, bleibt es, bis jemand vom Paar zurückkommt oder die App ihn als ersetzt erkennt und abtritt; sonst könnte ein lange abgeschnittener Host den Raum der anderen zurückholen.
- Tests: `takeover_test.dart` Gruppe „never two hosts moving the same game on“ (abgeschnittener Host steht still, während der Nachfolger übernimmt; Host ohne Paar beansprucht neu und spielt mit dem Tisch weiter), über eine Test-Leitung, die hängt statt abzubrechen.

### 5. Ausfälle klug erkennen

- Timeouts passen sich der gemessenen Laufzeit an (Relay, mobile Daten): Schwelle = max(feste Untergrenze, k · langsame Laufzeit), nach einem Fehlalarm (alter Host mit gleicher Epoche taucht wieder auf) großzügiger.
- Nach einer Übernahme gilt die alte Uhr weiter, bis der neue Uhrabgleich eingeschwungen ist.

### 6. Sicherheit der Übernahme und der Suche (aus der Mobile-Security-Vorlesung)

- **Sybil:** Nachfolger und Zeuge nicht mehr die ersten zwei Plätze, sondern zufällig unter den Kandidaten und von **verschiedenen Absenderadressen**; sonst hält ein Spieler mit zwei Geräten Raum und Schlüssel und liest alle Rollen.
- **Falsche Bonjour-Ansagen:** alle passenden Ansagen parallel probieren (`firstConnection`), einen neuen Host erst nach erfolgreichem Handshake als Nachfolger akzeptieren; Begrenzungen im WLAN pro Absenderadresse statt global.
  - **Umgesetzt (2026-10-28):** Ansagen gelten nur als Hinweis. `HostLocator.findAll` liefert alle passenden Ansagen, die beste pro Absenderadresse, höchstens 4, höchste Epoche zuerst; der Dialer wählt sie alle parallel, nur der echte Host besteht den Handshake mit dem Raumschlüssel. Dasselbe für den Eingang des Nachfolgers bei der Übernahme (`findCandidates`). Der Host des Spielleiters prüft eine Ansage mit höherer Epoche über eine eigene Probe-Verbindung (Handshake plus Willkommen mit höherer Epoche für sein Token) und schaltet erst danach um; seine eigene Sicht bleibt bis dahin, wo sie ist. Vorher trennte eine falsche Ansage ihn alle 4 s für bis zu 8 s. Tests: `room_finder_test.dart` (falsche hohe Epoche, viele Ansagen eines Fremden, falscher Eingang).
  - Begrenzungen pro Absenderadresse und die anderen Punkte dieses Abschnitts: auf Wunsch des Eigentümers vorerst nicht.
- **Seitenkanal klassische Nacht:** Nur Aufgerufene senden und bekommen ein Ack; Absender, Länge und Zeitpunkt verraten die Seherin. In geheimen Schritten senden alle im festen Takt (auf dem 3-s-Ping), Absichten warten auf den nächsten Takt.

### 7. Chaos-Test wie Jepsen

`chaos_test.dart` bekommt die Übernahme: Host stirbt endgültig, Host partitioniert und kehrt zurück, Nachfolger stirbt während der Übernahme. Invarianten: jede bestätigte Absicht wirkt; nie zwei weiterschaltende Hosts; alle Geräte landen bei derselben (Epoche, Version); kein Gerät zeigt eine Phase später als `showAt` + Toleranz.

## Sicherheit

- **Was schiefgehen kann:** vorgemerkte Sichten verraten zu früh etwas; ein alter Host oder ein Fremder im WLAN spaltet das Spiel; erneut gesendete Absichten wirken doppelt; ein Spieler erschleicht sich Nachfolger und Zeugen; Zeitmuster verraten Rollen.
- **Bewusst in Kauf genommen:** `voices` zeigt auch nachts, welches Gerät gerade weg ist. Das hört man am Tisch ohnehin (das Gerät spricht nicht); eine Rolle verrät es nicht.
- **Was es verhindert:** vorgemerkte Sichten sind dieselben gefilterten Sichten, nie früher als heute die Restzeit sichtbar ist; Lease und Epoche; Sequenzprüfung; zufällige Wahl über verschiedene Adressen; fester Sendetakt in geheimen Schritten.
- **Welche Tests es zeigen:** die Tests aus den Schritten 1, 2, 4 und 7, dazu ein Leck-Test „vorgemerkte Sicht enthält nichts, was die aktuelle Sicht des Empfängers nicht auch enthalten dürfte“ und ein Test, dass in der klassischen Nacht alle Geräte gleich viele, gleich große Nachrichten senden und bekommen.

## Protokoll

Version 12: `phaseEndsAt`, `showAt`/vorgemerkte Sicht, „zu spät“-Antwort, Vergleich über (Epoche, Version). Alte Clients werden wie bisher abgewiesen.

## Reihenfolge und Wochenende

Vor dem Spielabend (31.10./01.11.) nur **Schritt 1 und 2** (klein, große Wirkung, gut testbar) und die Generalprobe aus Task 020. Schritte 3 bis 7 danach, jeder auf eigenem Branch mit grünem `tool/check.sh`.
