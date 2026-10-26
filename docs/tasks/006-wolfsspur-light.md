# Task 006 – Wolfsspur light

**Status:** fertig
**Roadmap:** MVP-Sprint, Spur W (die volle Wolfsspur steht unter „Nach dem MVP“)

## Ziel

Ein erster Eindruck des Alleinstellungsmerkmals ([NIGHT_SOUNDS.md](../NIGHT_SOUNDS.md)) ohne genauen Uhrabgleich: Die Nacht klingt nach Nacht, und am Morgen gähnen die Handys.

## Umfang

- **Morgen-Gähnen** auf allen Geräten beim Wechsel zum Morgen.
- **Atmosphäre in der Nacht:** ein paar leise Geräusche (Wind, Grillen, Eule), zufällig verteilt. Sie verraten nichts: gleich auf allen Geräten bzw. unabhängig von Rollen und Aktionen.
- Optional: in der Stufe „Klassisch“ aus, ab „Whowolf“ an, einzeln abschaltbar (Task 004); Stummschalten pro Gerät.
- Eigene oder lizenzfreie Geräusche, Herkunft in `docs/DECISIONS.md` dokumentiert.

## Sicherheit

- Kein Geräusch darf von einer Rolle oder einer Nachtaktion abhängen (sonst Tell). Test: Die Geräusch-Planung ist eine reine Funktion von Startwert und Runde, nicht vom Zustand der Rollen.

## Fertig, wenn

- In einer Runde hörbar, abschaltbar, ohne Rückschlüsse auf Rollen; `ROADMAP.md` abgehakt.
