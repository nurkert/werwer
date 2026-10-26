# Task 004 – Hexe, Jäger, Amor und Spiel-Einstellungen

**Status:** fertig
**Roadmap:** MVP-Sprint, Spur F

## Ziel

Genug Rollen für richtige Runden und Einstellungen, mit denen der Gastgeber den Ablauf festlegt. Jede Figur (Persona) kann weiterhin jede Rolle bekommen.

## Umfang

1. **Rollen in `game_core`** (Regeln nur dort, Texte eigene, siehe `docs/LEGAL.md`):
   - **Hexe:** ein Heiltrank und ein Gifttrank pro Partie, je einmal. Sie sieht nachts das Opfer der Werwölfe und entscheidet nach ihnen.
   - **Jäger:** stirbt er, nimmt er sofort jemanden mit (auch durch Abstimmung). Eigener Zwischenschritt mit Timeout.
   - **Amor:** verbindet in der ersten Nacht zwei Spieler als Liebespaar. Stirbt einer, stirbt der andere. Ein gemischtes Paar (Dorf + Wolf) gewinnt nur, wenn beide allein übrig sind.
   - **Anti-Tell:** Alle ohne Aktion haben weiter ihre Tarnaufgabe; die Nacht dauert gleich lang und erzeugt gleich viel Netzverkehr, egal welche Rollen im Spiel sind.
   - Siegbedingungen, Reihenfolge der Nacht, Tod-Ketten (Liebespaar + Jäger) sauber und getestet.
2. **Alles Eigene ist optional, in Stufen.** Man soll Whowolf ganz reduziert spielen können, wie das Kartenspiel, nur mit der App als Erzähler, und dann schrittweise mehr dazunehmen. Vorgaben, die der Gastgeber mit einem Tipp wählt und danach im Detail ändern kann:
   - **Klassisch:** nur die Rollen, die App erzählt und zählt Stimmen; keine Schäfchen-Wertung, keine Wolfsspur, keine Atmosphäre, Figurenwahl optional.
   - **Whowolf:** dazu Schäfchen zählen mit Morgen-Wertung, Morgen-Gähnen, Atmosphäre.
   - **Volle Bühne:** alles, was es gibt (später auch die volle Wolfsspur).
   - Ausnahme mit Grund: Auch in „Klassisch“ tippen nachts alle etwas (eine schlichte neutrale Bestätigung statt Schäfchen), denn sonst verrät schon das Tippen am Tisch die Rollen. Das bleibt ein fester Teil der App, nicht abschaltbar.
3. **Einstellungen im Detail** (`GameSettings`, in der Lobby nur vom Gastgeber änderbar, alle sehen sie):
   - welche Rollen und wie viele (mit Vorschlag nach Spielerzahl),
   - Phasenzeiten (Nacht, Tag, Abstimmung),
   - Rollen nach dem Tod aufdecken,
   - Seherin sieht Rolle oder nur Lager,
   - Schäfchen zählen an/aus (bzw. nur neutrale Bestätigung),
   - Wolfsspur light und Atmosphäre an/aus (Task 006),
   - Figuren wählen an/aus,
   - Erzählstimme an/aus.
4. **Protokoll und App:** neue Absichten und Sichten (versioniert), Bildschirme für Hexe, Jäger, Amor und Liebespaar, Einstellungsseite.

## Sicherheit

- Sichten: Liebende sehen nur ihren Partner; die Hexe sieht nur das aktuelle Opfer; nichts davon taucht in fremden Sichten auf. Der bestehende Leak-Test für jeden Spieler deckt die neuen Rollen ab.
- Einstellungen werden streng geprüft (Grenzen für Zeiten und Anzahl) und nur von der Owner-Sitzung angenommen.
- Umsetzung: `viewFor` gibt `couple` nur den Liebenden und Amor, `victim` und `potions` nur der lebenden Hexe (in ihrem Schritt); `settings` nimmt der Host nur von der Owner-Sitzung und nur in der Lobby an, `GameSettings.validate` prüft die Grenzen; der Parser nimmt höchstens zwei Ziele, nur Sonderrollen ohne Doppelte und Zeiten bis 3600 s. Tests: `expectNoLeaks` für jeden Spieler (u. a. 300 Zufallspartien mit allen Rollen in `game_core/test/roles_test.dart`), Simulations- und Chaos-Test prüfen jede empfangene Sicht, `host_test` („only the owner changes the settings“), `protocol_test` („anything not exactly valid is refused“).

## Fertig, wenn

- Tests für jede Regel und ganze Partien mit allen Rollen über die öffentliche API; die Simulations- und Chaos-Tests nutzen die neuen Rollen.
- In der App spielbar, Deutsch und Englisch; `ROADMAP.md` abgehakt.
