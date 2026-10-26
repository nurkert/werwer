# Task 002 – Stabiles Netz: Fehler ausgleichen, ohne dass es jemand merkt

**Status:** fertig (Gerätetest 2026-10-26: iPhone als Host, Mac als Spieler; Abstimmungs-Szenario automatisiert in `app/integration_test/host_return_test.dart`)
**Roadmap:** MVP-Sprint, Spur S

## Ziel

Aus Sicht der Spieler läuft immer alles: kurz geschlossene Host-App, Netzwechsel, gesperrte Bildschirme, verlorene oder doppelte Nachrichten. Im Hintergrund wird ausgeglichen, im Vordergrund sieht man höchstens eine ruhige Pause. Die Konkurrenz scheitert laut Rezensionen genau hier, also ist das unser Unterbau zum Abheben.

Grundsatz: **Der Host fehlt kurz = normaler Spielzustand, kein Fehler.**

## Was schon da ist

- Host schickt bei jeder Änderung die komplette gefilterte Sicht (zustandsbasiert, heilt sich selbst).
- Sitzungstoken, Rejoin mit vollem Status, Host-Schnappschuss nach jeder Änderung, „Raum wiederherstellen“.
- App verbindet sich neu (`app/lib/src/net/game_session.dart`), gibt aber nach `maxReconnects` auf.
- Simulationstests in `packages/game_host/test/simulation_test.dart` (zufällige Partien, Abbrüche, Rejoins, Host-Absturz).

## Umfang

1. **Zustandsversion.** `StateMessage` bekommt eine fortlaufende Version (`GameHost` zählt bei jedem `_broadcast` hoch, im Schnappschuss gespeichert). Die App verwirft ältere Versionen.
2. **Aktionen mit Nummer und Bestätigung.**
   - Jede Absicht vom Client trägt eine Nummer pro Sitzung (`seq`).
   - Der Host merkt sich pro Sitzung die höchste verarbeitete Nummer (im Schnappschuss) und bestätigt mit `Ack(seq)`, auch für Doppelte, ohne sie erneut anzuwenden.
   - Die App hält unbestätigte Absichten in einer Warteschlange und schickt sie nach jedem Rejoin erneut.
   - Ergebnis: Keine Stimme geht verloren, keine zählt doppelt.
3. **Pausenmodus.**
   - Ist der Host nicht erreichbar, zeigt die App eine ruhige Pause („Der Erzähler holt kurz Luft …“), die eigene Rolle und die letzte Sicht bleiben sichtbar.
   - Die App gibt während einer laufenden Partie nicht auf (kein `maxReconnects` mehr während des Spiels; Backoff mit Zufallsanteil, höchstens alle paar Sekunden).
   - Nach einer Wiederherstellung startet der Phasen-Timer mit der **Restzeit** statt von vorn (Restzeit im Schnappschuss speichern).
4. **Host wiederfinden.**
   - Die App sucht den Host per Bonjour über Raumcode und Host-Schlüssel, nicht über die alte IP.
   - WLAN und Relay werden parallel versucht, das erste erfolgreiche gewinnt.
   - Der Host versucht beim Neustart zuerst den alten Port (gibt es schon).
5. **Plattformen.**
   - Android: Vordergrund-Dienst mit Benachrichtigung, solange ein Raum offen ist.
   - iOS: deutlicher Hinweis für den Gastgeber, die App offen zu lassen; nach dem Zurückkommen sofort wieder hosten (Raum aus dem Schnappschuss, gleicher Port).
6. **Chaos-Tests** (ersetzen die Testabende).
   - Ein simuliertes Netz (In-Memory-Transport) verliert, verzögert, verdoppelt und vertauscht Nachrichten und trennt Verbindungen zufällig.
   - Der Host wird an zufälligen Stellen beendet und aus dem letzten Schnappschuss wiederhergestellt.
   - Geprüft über Hunderte zufällige Partien (fester Seed pro Fall, damit Fehler reproduzierbar sind):
     - jede Partie endet regelkonform,
     - nach Ruhe stimmen alle Sichten mit `viewFor(state, id)` überein,
     - jede bestätigte Aktion wurde genau einmal angewendet,
     - keine Sicht enthält fremde Geheimnisse.
   - Dazu ein Test für die App-Seite (`GameSession`) mit demselben Netz.

## Sicherheit

- **Was kann schiefgehen:** Wiederholte oder gefälschte Nummern sollen Aktionen doppelt auslösen oder fremde blockieren; ein Angreifer flutet die Warteschlange; die Bonjour-Suche führt zu einem falschen Host.
- **Was schützt:** `seq` gilt nur innerhalb der eigenen Sitzung (Identität weiterhin nur aus der Sitzung); Grenzen für Nummernsprung und Warteschlangenlänge; Verbindung nach Bonjour weiterhin nur mit Host-Schlüssel aus QR bzw. Welcome (`secure_channel` lehnt falsche Hosts ab).
- **Welcher Test zeigt es:** Chaos-Tests oben, dazu ein Test, dass eine wiederholte `seq` genau einmal wirkt und eine fremde Sitzung keine Nummern einer anderen beeinflusst.

## Fertig, wenn

- Alle Chaos-Tests grün sind und in `tool/check.sh` laufen.
- Auf echten Geräten: Host schließt die App mitten in der Abstimmung, öffnet sie nach 30 Sekunden wieder, die Runde geht ohne Eingriff weiter.
- `ROADMAP.md` (Spur S) abgehakt, Entscheidungen in `DECISIONS.md`.
