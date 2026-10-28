# Task 019 – Geschlossene Räume verschwinden aus dem Hauptmenü

**Status:** offen (gemeldet 2026-10-28), Fehler
**Bezug:** `app/lib/src/net/discovery.dart` (`RoomFinder`), `app/lib/src/start_screen.dart` (Schnellbeitritt), Task 016 (ein selbst geschlossener Raum verschwindet aus der laufenden Suche dieses Geräts)

## Fehler

Der Eigentümer öffnet einen Raum und schließt ihn wieder. Im Hauptmenü steht danach weiter „Raum beitreten“ für diesen Raum, obwohl es ihn nicht mehr gibt. Ein Tipp führt ins Warten, und niemand kann bestätigen.

**Soll:** Der Schnellbeitritt zeigt einen Raum nur, wenn er **sicher noch offen und erreichbar** ist. Ein geschlossener Raum verschwindet sofort, auf diesem Gerät und auf allen anderen.

## Was es heute schon gibt

- `RoomFinder` listet Räume aus Bonjour/mDNS (`_found` bei *resolved/updated*, entfernt bei *lost*).
- `RoomFinder.closed(hostKey)` blendet Räume aus, die **dieses Gerät** selbst geschlossen hat (`HostedRoom.close()` ruft es auf, aber nur ohne `quietly`).
- Der Schnellbeitritt im Startbildschirm zeigt `_finder.rooms`, den zuletzt besuchten Raum zuerst (`start_screen.dart`, um Zeile 366).

## Vermutete Ursachen (zuerst nachstellen und bestätigen)

1. **mDNS-Cache:** Das System behält eine Ankündigung nach dem Abmelden noch eine Weile, oder die Abmeldung (Goodbye-Paket) geht verloren. Dann kommt nie ein *lost*-Ereignis, und der Raum bleibt stehen. Das betrifft vor allem **andere Geräte**, auf denen `RoomFinder.closed` nie aufgerufen wird.
2. **Leiser Abschluss:** `close(quietly: true)` markiert den Raum nicht als geschlossen. Das passiert bei der Übergabe an einen Nachfolger, aber auch, wenn eine neuere Epoche den Raum übernommen hat. Prüfen, ob der Raum des Eigentümers so geschlossen wurde.
3. **Neuer Startbildschirm:** Eine neue `RoomFinder`-Suche liest den Cache des Systems frisch ein. Prüfen, ob die statische `_closed`-Menge dabei greift (sie lebt nur, solange die App läuft).
4. **Neustart der App:** Nach einem Neustart ist `_closed` leer, und eine im Cache liegende Ankündigung erscheint wieder.

## Plan

1. **Nachstellen** auf zwei Geräten (Mac + iPhone): Raum öffnen, schließen, Hauptmenü auf beiden Geräten beobachten, auch nach einem Neustart der App. Festhalten, welche Ursache zutrifft.
2. **Erreichbarkeit prüfen statt der Ankündigung zu glauben:** Ein Raum erscheint im Schnellbeitritt erst, wenn sein Host auf der angekündigten Adresse antwortet, und er verschwindet, sobald er nicht mehr antwortet.
   - Prüfung: nur eine **TCP-Verbindung** zu `lan.ip:lan.port` mit kurzem Zeitlimit (ca. 1,5 s), sofort wieder schließen. Kein HTTP und kein WebSocket. So zählt die Prüfung nicht als Beitrittsversuch und nicht gegen die Bremse für Beitritte ohne QR-Code (`secure_channel`), und der Host sieht nichts außer einer kurzen Verbindung.
   - Wiederholen, solange der Startbildschirm offen ist (z. B. alle 4 s, nur für angezeigte Räume, höchstens eine Prüfung pro Raum gleichzeitig). Zweimal hintereinander keine Antwort heißt: Raum ausblenden, bis er sich neu ankündigt oder wieder antwortet.
   - Die Prüfung als einspritzbare Funktion in `RoomFinder` (`Future<bool> Function(LanAddress)`), damit sie ohne Netz testbar ist.
3. **Selbst geschlossene Räume** zusätzlich über den Neustart hinweg ausblenden: die Fingerabdrücke geschlossener Räume ein paar Stunden im Speicher der App halten (`Store`, mit Ablaufzeit), nicht nur in der statischen Menge.
4. **Beim Tippen absichern:** Antwortet der Host beim Schnellbeitritt nicht innerhalb weniger Sekunden, kommt ein klarer Hinweis („Dieser Raum ist nicht mehr offen“) statt endlosen Wartens, und der Raum verschwindet aus der Liste.
5. **Gleiches für `HostLocator`** prüfen: Er nutzt dieselbe Suche, um verlorene Hosts wiederzufinden. Dort darf eine tote Ankündigung keinen Wiederverbindungsversuch auslösen, der hängen bleibt.

## Tests

- `RoomFinder` mit einer falschen Prüffunktion:
  - Ein angekündigter, aber nicht antwortender Raum erscheint nie.
  - Ein antwortender Raum erscheint.
  - Einer, der aufhört zu antworten, verschwindet nach zwei Fehlversuchen.
  - Einer, der wieder antwortet, kommt zurück.
- Ein Raum, den dieses Gerät geschlossen hat, bleibt auch mit neuer Suche und nach einem simulierten Neustart ausgeblendet, bis die Ablaufzeit vorbei ist.
- Schnellbeitritt zu einem Raum, der nicht antwortet: Hinweis statt Warten (Widget-Test).
- Auf echten Geräten: Raum auf Gerät A schließen. Er verschwindet auf A sofort und auf B innerhalb weniger Sekunden, auch wenn Bonjour kein *lost* meldet.

## Sicherheit

- **Was schiefgehen kann:** Die Prüfung öffnet Verbindungen zu Adressen aus fremden Ankündigungen. Ein Angreifer im WLAN könnte damit Verbindungen zu beliebigen Zielen auslösen.
- **Was es verhindert:** Nur private IPv4-Adressen (wie heute schon in `_found`), nur der angekündigte Port, nur TCP ohne Daten, kurzes Zeitlimit, höchstens eine Prüfung pro Raum gleichzeitig, und die Liste der Räume ist begrenzt (neu: höchstens z. B. 32 Einträge).
- **Welcher Test es beweist:** Eine Ankündigung mit öffentlicher Adresse wird nie geprüft, und mehr als die Höchstzahl an Ankündigungen erzeugt keine weiteren Prüfungen.
