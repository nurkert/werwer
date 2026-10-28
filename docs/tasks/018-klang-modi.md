# Task 018 – Wo der Ton spielt: Erzähler, Stummschalten, Klang-Modi

**Status:** geplant (2026-10-28), zuerst ein Konzept, dann bauen
**Bezug:** [Task 010](010-wandernder-erzaehler.md) (wandernder Erzähler), [NIGHT_SOUNDS](../NIGHT_SOUNDS.md), [GAME_DESIGN](../GAME_DESIGN.md), Entscheidung vom 2026-10-26 „Wandernder Erzähler ohne neues Protokoll“

## Ausgangslage

Heute läuft die Erzählerstimme hörbar im Kreis um den Tisch, von Handy zu Handy. Rückmeldung des Eigentümers: Das ist im Moment störend. Der Gang läuft **immer**, besonders nachts, und er **dauert zu lange**. Außerdem fehlt eine einfache Antwort auf die Frage, wo am Tisch überhaupt Ton gespielt werden soll.

## Auftrag an den Agenten

Erst gründlich durchdenken, dann bauen. Am Anfang steht ein kurzes Konzept in diesem Task (Abschnitt „Konzept“). Es klärt Spielgefühl, Fairness, Technik und Bedienung und ist mit dem Eigentümer abgestimmt, bevor Code entsteht. Maßstab: Der Ton soll die Runde tragen und nie aufhalten.

## Wünsche des Eigentümers

1. **Der wandernde Erzähler wird richtig gut statt immer an.**
   - Wann er gehen darf und wann nicht: nicht in jeder Nacht, nicht bei jedem Satz.
   - Wie lange ein Gang höchstens dauert, und dass er nie die Phase verlängert.
   - Ob er nur besondere Momente trägt (Intro, erster Tod, Ende) und sonst still bleibt oder an einer Stelle spricht.
2. **Stummschalter oben**, gut sichtbar, auf jedem Gerät (heute gibt es ein Lautsprecher-Symbol in der Leiste des Spielbildschirms; zu prüfen, ob es reicht).
3. **Stumme Spieler fallen aus dem Kreis.** Wer stumm geschaltet hat, wird beim Gang des Erzählers und bei verteilten Klängen automatisch übersprungen, damit keine stillen Lücken entstehen. Wenn möglich auch „smart“: Erkennt das Gerät, dass der Ton aus oder ganz leise ist (Lautstärke null, Stummschalter, kein Ausgabegerät), zählt es ebenfalls als stumm.
4. **Klang-Modi für den Spielleiter** in den Spieleinstellungen:
   - **Alle Handys** (wie heute, mit Kreis).
   - **Nur bei mir:** Nur das Gerät des Spielleiters spielt Erzähler und Klänge.
   - **Nur diese Gruppe:** Der Spielleiter wählt einige Plätze aus, nur dort spielt der Ton.
   - **Nur bei diesem Spieler:** genau ein Gerät, zum Beispiel weil es mit einer Bluetooth-Box verbunden ist.

## Fragen, die das Konzept beantworten muss

- **Fairness und Anti-Tell:** Ein Klang darf nie verraten, wer nachts etwas tut. Was passiert mit Klängen, die heute pro Gerät spielen (Bedienklänge, Gähnen beim Aufwachen, Nachtgeräusche), wenn nur ein Gerät Ton hat? Der Gähn-Check (wer stumm ist, fällt morgens auf) muss in jedem Modus Sinn ergeben oder bewusst wegfallen.
- **Was „stumm“ verrät:** Ob jemand stumm ist, hängt nicht an der Rolle. Trotzdem prüfen, ob das Ein- und Ausschalten mitten in der Nacht ein Zeichen sein kann (z. B. nur zwischen Phasen übernehmen).
- **Erkennen von „Ton aus“:** Was iOS, Android, Desktop und Browser wirklich hergeben (Lautstärke, Stummschalter, Ausgabegerät, Bluetooth), ohne neue Berechtigungen und ohne Daten nach außen. Neue Abhängigkeiten nur mit Begründung (CLAUDE.md).
- **Protokoll:** Stumm-Zustand und Klang-Modus müssen zum Host und von dort zu allen, damit jedes Gerät denselben Gang plant. Das ist eine Protokolländerung (heute Version 8). Klang-Modus und Auswahl sind Einstellungen der Runde, die Rollen bleiben davon unberührt. Ob sie in `GameSettings` gehören oder als Tisch-Einstellung daneben, entscheidet das Konzept.
- **Ein Lautsprecher für alle:** Bei „nur bei mir“ oder „nur bei diesem Spieler“ spricht eine Stelle für den ganzen Tisch. Dann ist der Kreis aus, die Lautstärke passt sich an, und die Bildschirme der anderen zeigen den Text weiter.
- **Browser-Spieler (Task 017):** Wie sie in jedem Modus mitlaufen, mit Autoplay-Sperre und iOS-Stummschalter.

## Phasen (vorläufig, das Konzept darf sie ändern)

1. **Konzept** in diesem Task, mit dem Eigentümer abgestimmt.
2. **Erzähler zähmen:** klare Regeln, wann und wie lange er wandert, Tests für die Dauer (kein Gang verlängert eine Phase).
3. **Stumm teilen:** Stummschalter oben, Zustand zum Host, stumme Geräte fallen aus Kreis und Verteilung; „Ton aus“ automatisch erkennen, wo die Plattform es zuverlässig erlaubt.
4. **Klang-Modi:** Auswahl in den Spieleinstellungen (alle, nur ich, Gruppe, ein Spieler), sichtbar in der Lobby, Test, dass in jedem Modus genau die gewählten Geräte spielen.
5. **Prüfung am Tisch** mit echten Geräten, auch mit einer Bluetooth-Box.

## Sicherheit

Noch zu füllen im Konzept. Mindestens: Der Host prüft, dass nur der Spielleiter Klang-Modus und Auswahl ändert. Der Stumm-Zustand kommt nur aus der eigenen Sitzung (nie für andere Spieler setzbar) und wird beim Host in Größe und Rate begrenzt. Über den Ton gehen keine Spielgeheimnisse nach außen.
