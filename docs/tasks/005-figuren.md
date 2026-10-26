# Task 005 – Gleich viele Frauen und Männer bei den Figuren

**Status:** offen
**Roadmap:** MVP-Sprint, Spur F

## Ziel

Unter den wählbaren Figuren (Personas) sind gleich viele Frauen und Männer. Jede Figur kann weiterhin jede Rolle bekommen.

## Stand

11 Figuren (`Persona` in `packages/game_core/lib/src/role.dart`, Bilder in `design/source/figures/`, App-Versionen in `app/assets/figures/`). Grob gezählt: weiblich Magd, Laternenträgerin, Kräuterhexe, Lauscherin; männlich Grauwolf, Bauer, Jäger, Wächter, Fährtenleger; eher neutral Amor, Stille Pfote.

## Umfang

1. Zuerst anhand der Bilder genau zählen und festlegen, welche neuen Figuren nötig sind (Ziel z. B. 6 + 6 oder 7 + 7; neutrale Figuren wie Amor zählen extra).
2. Neue Figurenbilder **mit Codex erzeugen** (Entscheidung des Eigentümers), im Stil der bestehenden: Pappfigur im Mondbühnen-Stil, freigestellt, ohne Stab, Blick nach rechts, gleiche Größe und Lichtrichtung. Die bestehenden Figuren sind die Stilreferenz. Keine Motive, Namen oder Texte aus kommerziellen Werwolf-Ausgaben (`docs/LEGAL.md`).
3. Namen eigenständig und bewusst anders als Rollennamen (wie bei den bestehenden Personas), Deutsch und Englisch.
4. Einbinden: `Persona`-Enum, Protokoll, App-Assets (WebP, Gesamtgröße im Blick behalten), Website-„Besetzung“.

## Fertig, wenn

- Gleich viele weibliche und männliche Figuren in App und Website.
- Herkunft der Bilder in `docs/DECISIONS.md` vermerkt (erzeugt mit Codex, Datum).
