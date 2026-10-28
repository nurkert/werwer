# Task 020 – Ein reibungsloser Spielabend am Wochenende

**Status:** offen (2026-10-28), Ziel: Spielabend am Wochenende 31.10./01.11.2026
**Bezug:** [Task 018](018-klang-modi.md) (Klang, hier nur der schnelle Teil), [Task 019](019-geschlossene-raeume.md) (vorher erledigen), [Task 017](017-browser-uebers-netz.md) Phase 4 (Geräteprüfung, fließt in die Generalprobe ein), [GAME_DESIGN](../GAME_DESIGN.md)

Wunsch des Eigentümers: Am Wochenende soll ein Spiel ohne Hänger laufen. Dafür gibt es keine neuen Rollen, nur Tempo, Robustheit und eine Probe.

## Reihenfolge

1. **Task 019** (geschlossene Räume im Hauptmenü). Das ist der sichtbarste Fehler gleich zu Beginn eines Abends.
2. Dieser Task, Schritte 1 bis 3.
3. **Generalprobe ganz zum Schluss, vor Freitag (30.10.)**, zusammen mit den Geräteprüfungen aus Task 017 Phase 4.
4. Danach erst der große Task 018 (Klang-Konzept).

**Vor jedem Schritt prüfen, was es schon gibt.** Manches ist vielleicht schon da, zum Beispiel ein früheres Ende der Abstimmung oder Spieler, die keine Phase aufhalten (Roadmap, Task 002). Nur Fehlendes bauen, Vorhandenes mit einem Test belegen.

## 1. Erzähler zähmen (schneller Teil aus Task 018)

- [x] (mit Task 018) Ein Schalter in den Spieleinstellungen: wandernder Erzähler **aus / nur besondere Momente / immer**. Standard fürs Wochenende: *nur besondere Momente* (Intro, erster Tod, Spielende), sonst spricht die Stimme ohne Gang.
- [x] (mit Task 018) Kein Gang verlängert je eine Phase. Er wird gekürzt oder fällt aus, wenn die Zeit nicht reicht (Test).
- [x] (mit Task 018) Auf jedem Gerät ist oben das Stumm-Symbol gut sichtbar. Ein stummes Gerät wird beim Gang übersprungen, soweit das ohne Protokolländerung geht. Sonst kommt das in Task 018.

## 2. Tempo: niemand wartet unnötig

- [ ] **Abstimmung** endet, sobald alle Lebenden gestimmt haben (oder sich enthalten).
- [ ] **Diskussion:** Jeder kann „Wir sind so weit“ tippen. Bei Mehrheit der Lebenden geht es zur Abstimmung, nach kurzer Ankündigung („Gleich wird abgestimmt“, wenige Sekunden).
- [ ] **Nacht** endet, sobald alle nötigen Aktionen da sind. Dabei die Anti-Tell-Regeln beachten: Die Dauer darf nichts verraten, also nie kürzer als eine Mindestzeit, gleich für jede Nacht (siehe DECISIONS 2026-10-26, Mindestdauer pro Schritt).
- [ ] **Spielleiter-Knöpfe** (nur Spielleiter, vom Host geprüft): Pause/Weiter, Phase um 30 s verlängern, Phase beenden. Alle sehen eine ruhige Anzeige („Der Spielleiter hat pausiert“).
- [ ] **Zeiten pro Spielerzahl** sinnvoll vorbelegen (Diskussion, Abstimmung, Nacht), in den Einstellungen änderbar.

- [x] **Zeit zum Augenschließen** (Wunsch des Eigentümers, 2026-10-28): Wenn die Nacht beginnt, zeigt kein Bildschirm sofort, wer gerufen ist. Erst eine ruhige Übergangszeit auf allen Geräten gleich (Augen zu, Handy runter), dann erscheinen die Aktionen. Sonst sieht der Nachbar auf dem Handy daneben, dass jemand Werwolf ist. Gleiches beim Aufwachen der einzelnen Rollen in der klassischen Nacht. Umgesetzt in `NightPhase._holding`: zu Beginn der Nacht 6 s, bei jedem weiteren Schritt 4 s (klassisch) bzw. 3 s (Whowolf), gerechnet vom gemeinsamen Schrittbeginn, auf jedem Handy gleich. In der klassischen Nacht sehen auch die Gerufenen so lange den Mond, in der Whowolf-Nacht alle den Mond mit „Kurz die Augen zu“. Offen: am Tisch prüfen, ob die Zeiten passen.
- [x] **Einstellungen denken mit** (Wunsch des Eigentümers, 2026-10-28): Mit 3 Leuten ließ sich keine Testrunde starten, weil zu viele Rollen gewählt waren. Die Rollen passen sich automatisch an die Spielerzahl an (zu viele werden abgewählt, beim Wachsen der Runde die gewünschten wieder zugeschaltet), und die Lobby sagt in einer Zeile, was angepasst wurde. Was der Spielleiter selbst gewählt hat, bleibt als Wunsch erhalten. Umgesetzt: `GameSettings.fittedFor`/`droppedFor` lassen beim Start die letzten Sonderrollen weg (Amor, Jäger, Hexe, dann Seherin) und fallen bei zu vielen Werwölfen auf die vorgeschlagene Zahl zurück. Lobby und Einstellungen sagen „Für 3 Spieler ohne: …“ (Tests in `settings_test.dart`).

## 3. Ausfälle: ein Akku darf kein Spiel beenden

- [ ] **Wer fehlt, sieht man tagsüber:** In Diskussion und Abstimmung steht an einem getrennten Platz ein kleines Zeichen „nicht verbunden“. Nachts nie, weil es sonst ein Hinweis wäre.
- [ ] **Platz an ein anderes Gerät übergeben:** Der Spielleiter tippt auf den Platz und wählt „An anderes Gerät geben“. Es erscheint ein einmaliger QR-Code nur für diesen Platz. Das neue Gerät scannt ihn und sitzt mit Rolle und Stand am Platz, das alte Token wird ungültig.
- [ ] Fehlt jemand in seiner Aktion (nachts, Abstimmung), läuft die Phase nach Zeit weiter wie bisher. Prüfen, dass das in jeder Phase und Rolle stimmt (Jäger, Hexe, Amor, Seherin).

## 4. Generalprobe (ganz zum Schluss, vor Freitag)

- [ ] Eine komplette Runde mit **5–7 echten Geräten**, gemischt: iPhone als Host, weitere iPhones, Android, mindestens ein Browser im WLAN und einer über mobile Daten (Task 017).
- [ ] Drehbuch der Störungen: Host 20 s im Hintergrund, ein Spieler verliert das WLAN und kommt wieder, ein Platz wird übergeben, der Spielleiter pausiert und überspringt, ein Gerät ist stumm.
- [ ] Ergebnis hier festhalten: Was lief, was hakte, Bildrate und Akku nach einer Stunde. Gefundene Fehler sofort beheben oder als Task notieren.

## Sicherheit

- **Spielleiter-Knöpfe:** Nur die Sitzung des Spielleiters darf pausieren, verlängern oder beenden. Der Host prüft das wie heute bei den Einstellungen und begrenzt die Rate. Test: Ein anderer Spieler wird abgewiesen, der Zustand ändert sich nicht.
- **„Wir sind so weit“:** Eine Stimme pro lebendem Spieler, aus der eigenen Sitzung, nie für andere setzbar (Test).
- **Platz übergeben:**
  - Der Code gilt einmal und kurz (z. B. 2 Minuten) und nur für diesen Platz. Er steht im Fragment wie die Raumschlüssel und läuft über denselben verschlüsselten Handshake.
  - Danach ist das alte Token ungültig, damit nicht zwei Geräte auf einem Platz sitzen.
  - Erzeugen darf ihn nur der Spielleiter.
  - Tests: Ein Code geht kein zweites Mal, er verfällt, das alte Gerät fliegt heraus, und ein Nicht-Spielleiter kann keinen Code erzeugen.
- **Wer fehlt:** Die Anzeige erscheint nur tagsüber. Ein Test prüft, dass die Sicht in der Nacht keinen Verbindungszustand enthält.
- Protokolländerungen erhöhen `protocolVersion` und kommen in DECISIONS.
