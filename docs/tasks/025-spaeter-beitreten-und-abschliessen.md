# Task 025 – Später beitreten und Raum abschließen

Wunsch des Eigentümers (2026-10-29): Man soll jederzeit dazukommen können, zumindest im laufenden Spiel tagsüber. In den Einstellungen lässt sich festlegen, ob man dann als Geist oder als Dorfbewohner hereinkommt. Der Spielleiter bestätigt jeden Beitritt mit den Zeichen, in unserem Design. In der Lobby (und im Spiel) lässt sich der Raum abschließen: Er wird weiter angezeigt, aber niemand Neues kann beitreten.

Protokoll Version 17.

## Regeln (`game_core`)

- [x] Neue Einstellung `GameSettings.lateJoin` (`LateJoin.ghost` / `LateJoin.villager`), Standard **Geist**. Sie gehört wie Sprache und Zeiten zum Tisch, nicht zu einer Vorgabe (`withTableOf`).
- [x] Neue Aktion `JoinLate`: nur in der Phase `day`, sonst `wrongPhase`. Dieselben Namensregeln wie in der Lobby (`checkNewPlayer`, jetzt öffentlich und auch vom Host genutzt), höchstens 20 Plätze.
- [x] Als **Geist**: Rolle Dorfbewohner, von Anfang an tot, kein Eintrag in `deaths` (niemand ist gestorben), keine Stimme. Sieht, was die Toten am Tisch sehen (`GameSettings.ghosts`).
- [x] Als **Dorfbewohner**: lebt, stimmt ab der nächsten Abstimmung mit, nachts hat er die Deckaufgabe wie jeder Dorfbewohner. Er zählt für den Sieg des Dorfes mit und kann einen Werwolf-Sieg hinauszögern.
- [x] Die Sicht des Neuen ist gefiltert wie jede andere: keine fremden Rollen (außer aufgedeckten Toten), keine Nachtaktionen.

## Host

- [x] Ein neues Hello in einem laufenden Spiel kommt **immer** auf die Warteliste, auch mit QR-Code (vorher: `ByeReason.gameRunning`). Der Spieler bekommt `Waiting(running: true)` und sieht „Die Runde läuft schon. Der Spielleiter lässt dich rein, sobald es Tag ist.“
- [x] Der Spielleiter sieht die Warteliste nur in der Lobby und tagsüber (`StateMessage.pending`), nie nachts, in der Abstimmung oder beim Jägerschuss.
- [x] Reinlassen tagsüber → `JoinLate`. Kommt die Antwort an, wenn der Tag schon vorbei ist, bleibt der Spieler auf der Liste und wird am nächsten Tag wieder gefragt. Nach dem Spielende: `gameRunning`.
- [x] Wartezeit im laufenden Spiel bis 20 Minuten (`HostConfig.lateJoinWait`, eine Nacht lang), in der Lobby wie bisher 2 Minuten. Höchstens 6 warten gleichzeitig (`maxPending`).
- [x] Abschließen: `LeaderIntent(LeaderAction.lock / unlock)`, nur der Spielleiter, in jeder Phase. `StateMessage.locked` für alle. Wer gerade wartet, wird beim Abschließen mit `ByeReason.locked` verabschiedet.
- [x] Abgeschlossen: Jedes neue Hello ohne gültiges Token wird **vor** jeder Namensprüfung und jedem Prüfbild mit `ByeReason.locked` abgewiesen. Token, Wiederholung desselben Beitritts und Platzübergabe per Einmal-Code funktionieren weiter.
- [x] Der Zustand „abgeschlossen“ steht im Snapshot, übersteht also Absturz und Übernahme.

## App

- [x] Einstellungen, neuer Abschnitt „Raum“: Schalter „Raum abschließen“ (nur der Spielleiter) und die Wahl „Wer später kommt, spielt mit als Geist / Dorfbewohner“ mit Erklärung.
- [x] Im Spiel: Schloss in der Kopfleiste des Spielleiters (ab- und aufschließen).
- [x] Spielleiter-Karte `AdmitCard` mit Name, Zeichen (passen sich der Breite an), „Kommt als Geist dazu.“, Knöpfen (untereinander, wenn es eng ist) und „Noch N warten“. Im Spiel gleitet sie tagsüber von unten über den Bildschirm (`LateJoinPrompt`), bis der Spielleiter antwortet. Die Lobby nutzt dieselbe Karte.
- [x] Bonjour-Ansage mit `lock=1`; die Liste „Raum beitreten“ zeigt abgeschlossene Räume mit Schloss und „Abgeschlossen“, ohne Beitritt. Die Schnellknöpfe auf dem Startbildschirm lassen abgeschlossene Räume weg, außer dem eigenen, in dem dieses Gerät noch einen Platz hat (dann geht der Tipp mit dem Platz zurück).
- [x] Texte für `ByeReason.locked` und das Warten bis zum Tag, de und en.

## Tests

- [x] `game_core/test/late_join_test.dart`: nur tagsüber, Namensregeln, Geist ohne Tod und ohne Stimme, Dorfbewohner sieht nur sich und stimmt mit, Sieg des Dorfes mit dem Neuen, kein vorzeitiger Werwolf-Sieg.
- [x] `game_host/test/host_test.dart`, Gruppen „joining a running game“ und „a locked room“: Frage nur tagsüber und nur an den Spielleiter, Geist und Dorfbewohner über das Protokoll, Abweisen ohne Spuren (auch nicht im Snapshot), späte Antwort wartet auf den nächsten Tag, nur der Spielleiter lässt rein und schließt ab, abgeschlossen ohne Prüfbild abgewiesen, Rückkehr mit Token, abgeschlossen nach Wiederherstellung.
- [x] `protocol_test.dart`: neue Felder und Nachrichten im Rundlauf.
- [x] `app/test/late_join_prompt_test.dart`: Karte auf 320 und 390 px ohne Überlauf, im Spiel nachts keine Karte, tagsüber Karte und Reinlassen als Geist.
- [x] `app/test/quick_join_test.dart`: Schnellknöpfe ohne abgeschlossene Räume, außer mit eigenem Platz.

## Sicherheit

- **Was schiefgehen kann:** Ein Fremder im WLAN oder mit dem Raumcode drängt sich in eine laufende Partie, sieht Rollen oder stört die Runde. Ein abgeschlossener Raum lässt doch jemanden herein, weil nur die Oberfläche das Schloss kennt. Die Frage an den Spielleiter verrät nachts etwas über Rollen.
- **Was es verhindert:** Jeder späte Beitritt braucht die Bestätigung des Spielleiters mit dem Prüfbild, auch mit QR-Code. Die Identität kommt aus der Sitzung, die Rechte prüft der Host (`_ownerOnly`). Das Schloss setzt der Host durch, vor jeder Namensprüfung und jedem Prüfbild; die Bonjour-Ansage ist nur ein Hinweis für die Liste. Anzeigen oder Verstecken bringt keine Sicherheit: Die Ansage ist im WLAN ohnehin für alle sichtbar, und der Raumcode steht auf dem Tisch. Wichtig ist allein, dass der Host abweist. Die Frage kommt nur tagsüber, auf dem Gerät des Spielleiters, das ohnehin bekannt ist; nachts sieht er nichts. Der Neue bekommt eine gefilterte Sicht wie alle. Abgewiesene hinterlassen nichts im Spielstand. Alle neuen Felder sind Booleans oder feste Enums, Namen haben die bekannte Längengrenze.
- **Welcher Test es zeigt:** `a locked room turns new people away before any prompt, but the table comes back`, `also in a running game, and only the game leader locks`, `the game leader is asked by day only, never at night`, `refused, a latecomer leaves no trace`, `only the game leader lets latecomers in` (alle in `host_test.dart`), dazu `expectNoLeaks` in `late_join_test.dart`.

## Offen

- [ ] Am Tisch ausprobieren, wie sich das Hereinkommen als Geist anfühlt und ob der Tisch lieber Dorfbewohner hätte.
- [ ] Das Relay weiß nichts vom Schloss: Türcodes für die Seite des Servers gibt es weiter, der Host weist dann ab. Wenn es stört, beim Abschließen keine neuen Türcodes anfordern.
