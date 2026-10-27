# Task 011 – Klangbühne, Geister und Stichwahl

**Status:** in Arbeit (2026-10-27). Schritt 1 (Nacht als Klangraum) ist geschrieben, aber noch nicht durch `tool/check.sh` gelaufen.
**Roadmap:** vor dem ersten Abend mit Freunden

## Ziel

Bevor Whowolf am Tisch gezeigt wird, soll es sich fertig anfühlen: Die Handys sind zusammen **ein Klangraum um den Tisch**, wer stirbt, hat als **Geist** etwas davon, und ein Gleichstand endet in einer **Stichwahl**. Alles ist einzeln abschaltbar.

Leitregel für alle Klänge: **Was, wann und wo etwas erklingt, hängt nur von öffentlichen Werten ab** (Raum, Runde, Sitzordnung, Phasenbeginn in Host-Zeit), nie von einer Rolle oder Nachtaktion. Einzige Ausnahme bleibt die Wolfsspur, dort ist das Verraten gewollt.

## Schritte

### 1. Die Nacht als Klangraum (geschrieben)

`nightCues(room, round, seats:, seat:)` in `app/lib/src/game/atmosphere.dart` plant die Nacht für den eigenen Platz:

- **Teppich:** Grundwind und Grillen auf jedem Handy zu eigenen Zeitpunkten (Zufall aus Raum, Runde und Platz). Gleiche Inhalte laufen nie gleichzeitig, also kein Echo, und die Synchronisation spielt keine Rolle.
- **Böen laufen um den Tisch:** dieselbe Böe auf jedem Handy, um einen Schritt pro Platz versetzt (`_sweep` = 4 s für eine Runde, mindestens 300 ms pro Platz), Richtung und Startplatz aus Raum und Runde.
- **Eulen ziehen durch die Bäume:** jeder Ruf von einem Platz (die Nachbarn leise mit 30 %), der nächste ein oder zwei Plätze weiter.
- **Fix:** Die Nachtgeräusche laufen jetzt auf Host-Zeit (`_shared`), nicht mehr ab dem Eintreffen des Spielstands. Vorher spielte jedes Handy dieselbe Eule leicht versetzt, was nach Echo klang.

### 2. Schritte des Erzählers

Während der Erzähler (Task 010) um den Tisch geht, hört man ihn gehen, und zwar auf dem Handy, an dem er gerade ist.

- **Takt aus dem Gang:** Schritte nur, solange sich `NarratorWalk.positionAt` ändert, etwa 2 Schritte pro Platz. Steht er (Ziel erreicht), hört man keine Schritte mehr. Beim Herangehen an `to` werden sie langsamer.
- **Nie zweimal gleich:** ein Vorrat von 6–8 Schritt-Aufnahmen pro Untergrund. Jeder Schritt wählt per Zufall aus Raum, Runde und Schrittnummer, nie denselben wie der vorige. Dazu ±40 ms Zeit-Streuung und ±15 % Lautstärke, links und rechts leicht verschieden.
- **Untergrund nach Moment:** nachts Kies und Gras, morgens Holzdielen, bei Tod und Verbannung langsamer und schwerer. In späten Runden wird der Gang zögerlicher (zur Spannungskurve des Drehbuchs).
- **Nicht über die Stimme:** Unter einem gesprochenen Satz bleiben die Schritte bei etwa 30 %, in den Pausen zwischen den Sätzen sind sie voll.
- **Technik:** Jeder Schritt ist ein kurzer Einzelklang mit der Lautstärke `walk.gainAt(seat, ms)` zum Schrittzeitpunkt. Es braucht kein Nachführen der Lautstärke, nur `Sounds.play(…, gain:)`.

### 3. Mehr Klänge

CC0 von Freesound/Kenney, verarbeitet wie in `app/assets/sounds/CREDITS.md`. Handy-Lautsprecher geben kaum Bass wieder, also Klänge mit Energie zwischen 300 Hz und 6 kHz wählen, Hochpass bei etwa 150 Hz.

| Klang | Wann | Wie im Raum |
|---|---|---|
| Kirchenglocke | Mitternacht einer Nacht (eine zufällige Nacht pro Partie, nicht jede) | fern auf allen Handys, gleichzeitig, leise |
| Knarrende Tür | manche Nächte, zufällige Zeit | von einem Platz |
| Ferner Hund | manche Nächte | von einem Platz, kurz darauf ein zweiter von der anderen Seite |
| Regen | etwa jede vierte Nacht, aus Raum und Runde | Teppich, alle Handys, eigene Einsätze |
| Vögel, Dorfgeräusche | am Tag während der Diskussion, sehr leise | Teppich |
| Herzschlag | bei der Abstimmung, steigt in den letzten 20 s an | alle gleichzeitig (gemeinsamer Puls) |
| Schritte | siehe Schritt 2 | wandernd |

Was nie vorkommen darf: Wolfsheulen aus einer Richtung. Die Leute am Tisch würden es als Hinweis lesen.

### 4. Stichwahl bei Gleichstand

- **Einstellung `tieRule`:** `nobody` (wie bisher: niemand stirbt) oder `runoff`. Standard: `runoff` in den Stufen Whowolf und Volle Bühne, `nobody` in Klassisch? (offen, siehe unten)
- **Ablauf:** Bei Gleichstand zwischen den Meistgewählten folgt sofort eine zweite Abstimmung, nur über diese. Im Spielstand steht dafür `runoff: [PlayerId]`, öffentlich. Die Zeit ist die halbe `voteTime`. Ein zweiter Gleichstand bedeutet: niemand stirbt, die Nacht beginnt.
- **Wer abstimmt:** alle Lebenden. Wer selbst in der Stichwahl steht, darf weiter nicht für sich selbst stimmen.
- **Ereignis `RunoffStarted(candidates)`** für den Erzähler. Für eine neue Ansage braucht es neue Aufnahmen (`tool/voice/script.json`). Bis dahin kommt der Text auf den Bildschirm.
- **Protokoll:** Die Einstellung und `runoff` müssen serialisiert und geprüft werden (Kandidaten müssen lebende Spieler sein, höchstens so viele wie Spieler).

### 5. Geistermodus

Wer tot ist, hält sonst ein Handy ohne Aufgabe in der Hand. Im Kartenspiel dürfen die Toten oft zuschauen. Das bilden wir nach, einstellbar.

- **Einstellung `ghosts`:**
  - `off`: wie bisher
  - `roles`: Tote sehen alle Rollen und das Liebespaar
  - `everything`: zusätzlich live, was nachts passiert (Wahl des Rudels, Blick der Seherin, Tränke der Hexe, Türzeichen-Versuch) und wer wen wählt
- **Nur für Tote ohne Aufgabe:** Der Jäger in `Phase.hunterShot` ist tot, muss aber noch schießen. Er bekommt den Geisterblick erst nach dem Schuss, sonst wüsste er, wen er treffen soll. Diese Lücke muss ein eigener Test absichern.
- **Gegen das Spicken der Lebenden:** Geisterwissen nur bei gedrücktem „Geisterblick“ (Halten zum Ansehen). Danach dimmt der Bildschirm. Wer neben einem Geist sitzt, sieht nicht zufällig die Rollen.
- **Geister schweigen:** Beim Tod erklärt ein kurzer Hinweis, dass Geister nichts verraten dürfen. Dazu passt, dass die Rolle aufgedeckt wird.
- **Sicherheit (SECURITY_DESIGN):**
  - `viewFor` gibt Geisterwissen nur bei passender Einstellung und nur an Tote ohne Aufgabe heraus.
  - `expectNoLeaks` bekommt die drei Stufen als erlaubte Ausnahmen, und der Zufallspartien-Test läuft mit allen drei Stufen.
  - Der Host schickt bei `off` nachweislich nichts davon.
  - Die neuen Felder der Sicht bekommen im Protokoll Größengrenzen.
- **Später denkbar:** Geister wählen gemeinsam einen „Spuk“ (z. B. einmal pro Partie ein Geräusch bei einem Lebenden), ohne Einfluss auf die Regeln.

### 6. Synchronisation verbessern (nach Messung)

1. **Messen:** Zwei Handys spielen gleichzeitig einen Klick, ein drittes nimmt auf, den Versatz in Audacity ablesen. Mit WLAN-Handys und mit Bluetooth-Box.
2. Dann der Reihe nach:
   - monotone Uhr (`Stopwatch`) statt `DateTime.now()` für Abgleich und Planung
   - bei Verspätung mitten im Clip einsteigen (`seek`) statt zu schweigen
   - `flutter_soloud` als Ersatz für `audioplayers` prüfen (Maintainer, Lizenz, Aktivität, siehe CLAUDE.md)
   - Ausgabe-Latenz pro Gerät abziehen (iOS `outputLatency`)

## Offene Entscheidungen

- Standards der Stufen für `ghosts` und `tieRule`
- Welche Klänge konkret (Vorschläge mit Freesound-Links folgen)

## Sicherheit

- **Was schiefgehen kann:**
  - Klänge verraten Rollen.
  - Geisterwissen geht an Lebende oder an den schießenden Jäger.
  - Neue Protokollfelder sind zu groß oder ungültig.
- **Was es verhindert:**
  - Klänge sind reine Funktionen öffentlicher Werte.
  - `viewFor` prüft „tot und ohne Aufgabe“ und die Einstellung.
  - Das Protokoll validiert und begrenzt.
- **Welche Tests es beweisen:**
  - `atmosphere_test` („from public values only“, Platz-Tests)
  - `expectNoLeaks` mit allen Geisterstufen
  - ein Test zum Jäger-Schuss
  - Protokoll-Tests für die neuen Felder
