# Task 003 – Mondbühne in der App, Figuren als Pappmodell

**Status:** offen
**Roadmap:** MVP-Sprint, Spur D

## Ziel

Die App sieht aus und fühlt sich an wie die Website: verspielt, aber ernst zu nehmen. Im Moment wirkt sie noch zu steril. Grundlage sind `docs/DESIGN.md` und die gemeinsamen Design-Tokens (`tool/tokens.dart` erzeugt Website-CSS und `app/lib/src/palette.g.dart`).

## Umfang

1. **Einheitliches Design.**
   - Papier-Hintergrund mit Struktur, Pappkarten statt flacher Flächen, Bühnenrahmen, Lilita One für Überschriften, Stempel wie auf der Website.
   - Alles aus Tokens und wenigen gemeinsamen Komponenten (`app/lib/src/game/widgets.dart`), keine Einzelfarben in Bildschirmen.
2. **Figuren als Pappmodell mit Tiefe** (App und Website gleich).
   - Beim Umdrehen ist eine echte Kartonkante zu sehen: mehrere leicht versetzte Ebenen bzw. ein Kantenstreifen, abgedunkelt.
   - Die Rückseite entsteht aus dem Umriss der Figur (Alpha-Maske): graue Pappe mit Struktur und Stempel, keine eigenen Grafiken nötig.
   - App: Flutter-`Transform` mit Perspektive; Website: CSS 3D in den bestehenden Figuren-Komponenten.
   - Animationen kurz und ruhig, mit „Bewegung reduzieren“ abschaltbar.
3. **Jeder Bildschirm durchdacht.** Start, Raumsuche/Beitritt, Lobby mit Tischkreis, Einstellungen, Rolle ansehen, Nacht (Aktion bzw. Schäfchen), Morgen, Tag, Abstimmung, Ende, Pause (aus Task 002). Leere Zustände, Fehlertexte in Alltagssprache, große Tippflächen.

## Fertig, wenn

- Alle Bildschirme nutzen die gemeinsamen Komponenten und Tokens; Screenshots in Hell-/Dunkel-Umgebung geprüft.
- Die Figur dreht sich in App und Website mit sichtbarer Kante und Rückseite.
- Widget-Tests für die Komponenten; `tool/check.sh` grün.
