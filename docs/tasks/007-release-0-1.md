# Task 007 – Release 0.1 (MVP)

**Status:** vorbereitet. Offen sind nur Schritte, die der Eigentümer macht oder freigibt:
1. ~~Rauchtest auf echten Geräten~~ erledigt 2026-10-26 (iPhone als Host, Mac als Spieler).
2. `CHANGELOG.md`: Datum bei 0.1.0 eintragen, dann `git tag v0.1.0 && git push --tags` (der Workflow veröffentlicht 0.1.0 als richtiges Release mit dem Titel „developer beta“ und baut die Download-Seite neu).
3. Bewusst nach 0.1 verschoben: TestFlight und signiertes macOS (Apple-Secrets nötig), externer Krypto-Review (Pflicht vor den Stores).
**Roadmap:** M6 – Release 0.1, Ziel 2026-11-01

## Ziel

Tasks 002–006 sind fertig, und 0.1.0 ist als GitHub-Release mit Website veröffentlicht, sodass man es Freunden zeigen kann.

## Umfang

- Alle Punkte aus M6 in `ROADMAP.md`, soweit bis Sonntag machbar; was nicht passt, bewusst nach hinten schieben und in `DECISIONS.md` begründen.
- 0.1 bleibt als **Entwickler-Beta** gekennzeichnet, weil der externe Krypto-Review noch aussteht (Pflicht vor den Stores).
- Kurzer Rauchtest auf echten Geräten vor dem Tag: iPhone als Host, Mac und Android als Spieler; Host schließt die App mitten in der Partie und öffnet sie wieder.
- `CHANGELOG.md` (0.1.0), Website-Download und Release-Notes aktualisieren, dann `git tag v0.1.0`.

## Fertig, wenn

- Der Release-Lauf ist grün, die Downloads funktionieren, und die Website zeigt 0.1.0.
