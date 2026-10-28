# Task 021 – Nahtlos weiterspielen: Fehlertoleranz nach Lehrbuch

**Status:** geplant (2026-10-28), wartet auf die Freigabe des Eigentümers
**Bezug:** [ARCHITECTURE](../ARCHITECTURE.md), [SECURITY_DESIGN](../SECURITY_DESIGN.md), Task 002 (stabiles Netz), Task 008 (Host-Übernahme), Task 020 (Spielabend)

## Ziel

Wer einmal angefangen hat, spielt bis zum Ende, auch wenn das WLAN hakt, ein Handy kurz weg ist, jemand geht oder der Host ausfällt. Kurze Unterbrechungen merkt am Tisch niemand. Übergänge sind **vorher vereinbart**: Ein Gerät, das einen Befehl verpasst, schaltet trotzdem pünktlich um und hängt nie hinterher.

Grundlage sind zwei Vorlesungen des Eigentümers (Uni Ulm): *Fault-tolerant Distributed Systems* (Primary-Backup, Leases, Epochen, Failure Detectors, Chaos-Tests) und *Security and Privacy in Mobile Systems* (Pairing über einen Zweitkanal, Sybil, Rogue Host, Seitenkanäle). Aus der MANET-Vorlesung passt Routing **nicht**: Whowolf ist ein Stern um den Host mit einem Sprung, kein Multi-Hop-Netz.

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

### 2. Zeitpunkte absolut in Host-Zeit

**Befund:** `phaseEndsInMs` ist relativ; der Client rechnet ohne Laufzeit und ohne Uhrabgleich, der Snapshot speichert die Restzeit. Nach einer Übernahme verlängert sich die Phase um die Ausfallzeit.

- `StateMessage` trägt `phaseEndsAt` in Host-Zeit (wie schon `phaseAt`), Anzeige über `ClockSync.toLocal`.
- Der Snapshot speichert die Deadline absolut; der Nachfolger übernimmt sie über seinen Uhrabgleich zum alten Host. Die Phase endet wie geplant, ist sie schon vorbei, sofort.
- Sichten werden über **(Epoche, Version)** verglichen, nie über die Version allein.

### 3. Übergänge vorher vereinbaren

- Kurz vor dem Ende eines Schritts (T − Δ, Δ etwa 1,5 s) schließt der Host die Eingaben, rechnet den Übergang aus, speichert und versiegelt ihn für den Nachfolger und schickt jedem Gerät **seine nächste gefilterte Sicht mit `showAt = T`**.
- Jedes Gerät schaltet zum Zeitpunkt T selbst um, auch ohne Verbindung in diesem Augenblick. Gilt nur innerhalb der Epoche; eine neue Epoche ersetzt vorgemerkte Sichten.
- Absichten nach dem Eingabeschluss bekommen eine klare Antwort („zu spät“), nie Schweigen.
- Wo es den Spielablauf nicht verändert (Ende von Diskussion, Nachtschritt, Abstimmung nach Zeit): ja. Vorzeitige Enden („alle haben gestimmt“) laufen weiter sofort, mit `showAt` = jetzt + kleiner Puffer, damit alle gleichzeitig umschalten.

### 4. Nie zwei Hosts: Leader-Lease

**Befund:** Bei einer Partition übernimmt der Nachfolger, während der alte Host mit seinen Spielern weiterschaltet (Split Brain).

- Der Host schaltet Phasen nur weiter und bestätigt nur, solange er in den letzten 4 s (unter der Übernahmeschwelle von 6 s) von Nachfolger **oder** Zeuge gehört hat. Sonst friert er ein und zeigt die Pause.
- Kleine Tische ohne Nachfolger und Zeuge: keine Lease, wie heute.
- Test: Host partitioniert, kommt nach 20 s zurück; es gab nie zwei weiterschaltende Hosts, alle landen beim Gewinner.

### 5. Ausfälle klug erkennen

- Timeouts passen sich der gemessenen Laufzeit an (Relay, mobile Daten): Schwelle = max(feste Untergrenze, k · langsame Laufzeit), nach einem Fehlalarm (alter Host mit gleicher Epoche taucht wieder auf) großzügiger.
- Nach einer Übernahme gilt die alte Uhr weiter, bis der neue Uhrabgleich eingeschwungen ist.

### 6. Sicherheit der Übernahme und der Suche (aus der Mobile-Security-Vorlesung)

- **Sybil:** Nachfolger und Zeuge nicht mehr die ersten zwei Plätze, sondern zufällig unter den Kandidaten und von **verschiedenen Absenderadressen**; sonst hält ein Spieler mit zwei Geräten Raum und Schlüssel und liest alle Rollen.
- **Falsche Bonjour-Ansagen:** alle passenden Ansagen parallel probieren (`firstConnection`), einen neuen Host erst nach erfolgreichem Handshake als Nachfolger akzeptieren; Begrenzungen im WLAN pro Absenderadresse statt global.
- **Seitenkanal klassische Nacht:** Nur Aufgerufene senden und bekommen ein Ack; Absender, Länge und Zeitpunkt verraten die Seherin. In geheimen Schritten senden alle im festen Takt (auf dem 3-s-Ping), Absichten warten auf den nächsten Takt.

### 7. Chaos-Test wie Jepsen

`chaos_test.dart` bekommt die Übernahme: Host stirbt endgültig, Host partitioniert und kehrt zurück, Nachfolger stirbt während der Übernahme. Invarianten: jede bestätigte Absicht wirkt; nie zwei weiterschaltende Hosts; alle Geräte landen bei derselben (Epoche, Version); kein Gerät zeigt eine Phase später als `showAt` + Toleranz.

## Sicherheit

- **Was schiefgehen kann:** vorgemerkte Sichten verraten zu früh etwas; ein alter Host oder ein Fremder im WLAN spaltet das Spiel; erneut gesendete Absichten wirken doppelt; ein Spieler erschleicht sich Nachfolger und Zeugen; Zeitmuster verraten Rollen.
- **Was es verhindert:** vorgemerkte Sichten sind dieselben gefilterten Sichten, nie früher als heute die Restzeit sichtbar ist; Lease und Epoche; Sequenzprüfung; zufällige Wahl über verschiedene Adressen; fester Sendetakt in geheimen Schritten.
- **Welche Tests es zeigen:** die Tests aus den Schritten 1, 2, 4 und 7, dazu ein Leck-Test „vorgemerkte Sicht enthält nichts, was die aktuelle Sicht des Empfängers nicht auch enthalten dürfte“ und ein Test, dass in der klassischen Nacht alle Geräte gleich viele, gleich große Nachrichten senden und bekommen.

## Protokoll

Version 12: `phaseEndsAt`, `showAt`/vorgemerkte Sicht, „zu spät“-Antwort, Vergleich über (Epoche, Version). Alte Clients werden wie bisher abgewiesen.

## Reihenfolge und Wochenende

Vor dem Spielabend (31.10./01.11.) nur **Schritt 1 und 2** (klein, große Wirkung, gut testbar) und die Generalprobe aus Task 020. Schritte 3 bis 7 danach, jeder auf eigenem Branch mit grünem `tool/check.sh`.
