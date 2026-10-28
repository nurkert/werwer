# Task 018 – Wo der Ton spielt: Erzähler, Stummschalten, Klang-Modi

**Status:** Konzept abgestimmt (2026-10-28), in Arbeit
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

## Konzept (mit dem Eigentümer abgestimmt, 2026-10-28)

Heute verlängert die Stimme keine Phase (die Zeiten laufen beim Host unabhängig), aber **jeder** Satz wandert im Kreis über **alle** Handys, auch beim Rufen jeder Rolle in jeder Nacht. Das wirkt lang und unruhig. Das Konzept dreht drei Regler: *was* gesprochen wird, *wie* die Stimme geht, und *wo* überhaupt Ton spielt.

### 1. Was gesprochen wird: Erzähler aus / besondere Momente / immer

Neue Einstellung `narratorMode` (ersetzt den Schalter `narratorVoice`):

- **Aus:** nur Text auf den Bildschirmen.
- **Besondere Momente (Standard):** Intro, Nachtbeginn (in der klassischen Nacht auch Einschlafen und das Rufen der Rollen, sonst kann niemand mit geschlossenen Augen spielen), die Nachricht am Morgen (wer starb), das Ergebnis der Abstimmung, der Jäger, der Aufruf zur Abstimmung und das Ende. Still bleiben: „Rollen werden verteilt“, „Diskutiert“, Stichwahl, Liebeskummer und das Nennen der Rolle eines Toten (das zeigt der Bildschirm).
- **Immer:** alle Sätze wie heute.

Kein Satz darf über das Ende der Phase hinaus laufen: Was nicht mehr ganz hineinpasst, fällt weg (`plan(deadline: …)`, Test).

### 2. Wie die Stimme geht: erzählerisch, nie verräterisch

Jeder Satz bekommt einen **Gang**, ausgewählt aus der Art des Moments und einem Hash aus Raumcode, Runde und Satz. Das sind nur öffentliche Werte, also auf jedem Handy gleich und unabhängig von Rollen:

- **Schlendern:** langsam im Kreis (Intro, Morgen).
- **Eilen:** schnell im Kreis (die Nacht bricht herein, späte Runden, Abstimmung).
- **Quer übers Feld:** die Stimme springt direkt von Platz zu Platz über den Tisch, jeweils grob gegenüber, mit kurzer Überblendung (Nachtbeginn, Spielende).
- **Stehen:** ein Platz für den ganzen Satz (kurze Sätze, das Rufen der Rollen).

Regeln gegen Verrat:

- Der Gang hängt **nie** an einer Rolle oder Nachtaktion. Beim Rufen der Rollen steht die Stimme an einem Platz, der nur aus dem Hash kommt: nicht beim Werwolf, nicht bei der Seherin.
- Zu einer Person geht sie höchstens, wenn deren Schicksal schon öffentlich ist (Tote, Ausgestimmte, Jäger), und auch dann nur manchmal (Hash). So ist „er läuft zu dir“ kein Muster.

### 3. Wo Ton spielt: Klang-Modus

Neue Einstellungen `soundMode` (`everyone` / `chosen`) und `soundSeats` (Plätze). In der Bedienung sind es vier Möglichkeiten:

- **Alle Handys** (Standard).
- **Nur bei mir:** der Platz des Spielleiters.
- **Eine Gruppe:** mehrere Plätze.
- **Ein Spieler:** genau ein Platz, z. B. mit Bluetooth-Box.

Die **Lautsprecher** sind die gewählten Plätze ohne die stummen Geräte. Sitzt keiner der gewählten Plätze mehr am Tisch, spielen alle. Der Erzähler geht nur über die Lautsprecher, in ihrer Sitzreihenfolge. Gong, Hahn, Gähnen, Nachtgeräusche und Wolfsspur spielen nur dort.

Auf allen anderen Handys spielen nur die **eigenen Tipp-Klänge**. Die verraten nichts, weil alle gleich tippen. Der Gähn-Check entfällt auf Handys ohne Ton, weil er dort nichts prüfen kann.

### 4. Stumm teilen und erkennen

- Der Stumm-Knopf oben schickt den Zustand an den Host (`Silent`, nur für die eigene Sitzung, Rate begrenzt).
- **Automatisch:** Steht die Lautstärke des Geräts auf null, gilt es als stumm (Paket `volume_controller`, MIT, Android/iOS/macOS/Windows/Linux; den iPhone-Stummschalter kann keine App lesen). Im Browser gibt es keine Erkennung.
- **Gegen Verrat:** Der Host gibt die stummen Plätze nur zum Beginn einer Phase weiter (in der Lobby sofort). Wer mitten in der Nacht stumm schaltet, ändert den Gang erst in der nächsten Phase. Stumm sein hängt nicht an der Rolle.

### Protokoll

Version 9:
- `GameSettings` bekommt `narratorMode`, `soundMode`, `soundSeats` (höchstens `maxPlayers` Einträge).
- Neue Nachricht `Silent` vom Spieler.
- `StateMessage.silent`: die stummen Plätze des Phasenbeginns.

Klang gehört wie Erzählerstimme und Atmosphäre zu den Einstellungen der Runde und bleibt deshalb in `GameSettings`. Für die Regeln ist es bedeutungslos.

## Phasen (vorläufig, das Konzept darf sie ändern)

1. **Konzept** in diesem Task, mit dem Eigentümer abgestimmt.
2. **Erzähler zähmen:** klare Regeln, wann und wie lange er wandert, Tests für die Dauer (kein Gang verlängert eine Phase).
3. **Stumm teilen:** Stummschalter oben, Zustand zum Host, stumme Geräte fallen aus Kreis und Verteilung; „Ton aus“ automatisch erkennen, wo die Plattform es zuverlässig erlaubt.
4. **Klang-Modi:** Auswahl in den Spieleinstellungen (alle, nur ich, Gruppe, ein Spieler), sichtbar in der Lobby, Test, dass in jedem Modus genau die gewählten Geräte spielen.
5. **Prüfung am Tisch** mit echten Geräten, auch mit einer Bluetooth-Box.

## Sicherheit

Noch zu füllen im Konzept. Mindestens: Der Host prüft, dass nur der Spielleiter Klang-Modus und Auswahl ändert. Der Stumm-Zustand kommt nur aus der eigenen Sitzung (nie für andere Spieler setzbar) und wird beim Host in Größe und Rate begrenzt. Über den Ton gehen keine Spielgeheimnisse nach außen.
