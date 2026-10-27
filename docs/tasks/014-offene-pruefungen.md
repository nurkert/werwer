# Task 014 – Offene Prüfungen

**Status:** erledigt (2026-10-27)
**Bezug:** [Task 013](013-feinschliff-abend.md)

Alle Wünsche aus dem Chat vom 27. Oktober sind in Task 013 umgesetzt (der Verlauf ist noch einmal vollständig durchgesehen, auch die Nachrichten mitten in der Arbeit). Hier steht nur, was noch nicht mit eigenen Augen geprüft ist und sich ohne den Eigentümer prüfen lässt. Neue Wünsche aus dem Chat kommen hier dazu.

- [x] **Flug der Figur in der Lobby als Bildfolge:** `FLIGHT=1` im Screenshot-Test (`app/test/screens_test.dart`) tippt auf der Figurenseite eine freie Figur an und hält den Flug in Einzelbildern fest (`<sprache>-02-lobby-flight-<n>.png`). Geprüft: die Figur wächst aus ihrer Karte und fliegt mit einer Drehung nach oben, die Seite scrollt mit, die Karte bleibt als Lichtfeld zurück, die alte Figur gleitet in ihre Karte zurück. Ist die große Figur beim Antippen nicht im Bild, fliegt sie nicht sichtbar weg (wie gewünscht).
