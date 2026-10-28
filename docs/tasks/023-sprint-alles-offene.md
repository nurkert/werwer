# Task 023 – Sprint: alles Offene bis 0.2.0

**Status:** offen (2026-10-28), Ziel: alles in diesem Sprint, Abschluss mit Release 0.2.0 und einer Generalprobe am Tisch
**Bezug:** [Task 018](018-klang-modi.md) (Klang), [Task 020](020-spielabend-wochenende.md) (Spielabend), [Task 021](021-nahtlos-fehlertolerant.md) (Fehlertoleranz, eigener Agent), [Task 022](022-code-beitritt.md) (Beitritt per Code, läuft), [ROADMAP](../ROADMAP.md) 6d, [SECURITY_DESIGN](../SECURITY_DESIGN.md)

Wunsch des Eigentümers (2026-10-28): Alles, was offen ist, auch was nur am Rand erwähnt oder für später vorgemerkt wurde, kommt in diesen Sprint und wird Schritt für Schritt abgearbeitet.

## Arbeitsweise

- Jeder Punkt kommt auf einen eigenen Branch. Ist `tool/check.sh` grün, wird gepusht, nach `main` gemergt (Fast-Forward nach Rebase) und der Branch gelöscht. Ein zweiter Agent arbeitet parallel im Repo.
- **Vor jedem Punkt prüfen, was es schon gibt.** Nur Fehlendes bauen, Vorhandenes mit einem Test belegen.
- Die Anti-Tell-Regel gilt überall: Kein Bildschirm, kein Klang, keine Dauer verrät eine Rolle.
- Jede neue Netz- oder Speicherfunktion bekommt hier eine Sicherheitsnotiz mit Test.
- Ändert sich eine Nachricht, ist die Protokollversion 12 schon erhöht (noch nicht veröffentlicht). Bis 0.2.0 reicht das. Eine neue Version braucht es nur, wenn nach einem Release etwas dazukommt.
- Nach jeder Phase wird abgehakt. Neue Entscheidungen kommen in DECISIONS.md.

## Reihenfolge

Zuerst kommen die kleinen Fehler und Unklarheiten (A), die jeder Spieler sofort merkt. Danach die Bedienung der Rollen (B), der Desktop (C) und der Wiederbeitritt (D). Dann der große Umbau des Erzählers (E) und die neuen Inhalte (F). Zum Schluss Release und Probe (G). Was auf Aufnahmen des Eigentümers wartet (F3, F4), wird vorbereitet und eingebaut, sobald die Aufnahmen da sind.

---

## A – Kleine Fehler, klare Bildschirme

- [x] **A1 Keine IP-Adresse im Beitrittsdialog.** (erledigt: „Über euer WLAN“ statt der Adresse) Der Dialog zeigt die IP des Hosts. Das ist verwirrend und unnötig: Er soll nur den Raumnamen und den Spielleiter zeigen. Die Adresse steht nur unter „Verbindungsdetails“.
- [x] **A2 Versions-Meldung statt Timeout** auf der Browser-Beitrittsseite. Passt die Protokollversion der Seite nicht zum Host, steht da klar „Dein Spielleiter hat eine andere Version“ mit einem Hinweis, was zu tun ist. Es läuft nicht in einen Timeout „Gastgeber nicht erreichbar“. Das gilt ebenso in der App. Test: Hello mit falscher Version, dann eine sichtbare Meldung.
  - Erledigt: `VersionMismatch` und eine Versionsnachricht `{"v":…,"type":"version"}`, die ab Version 12 jede Version versteht. Der Host schickt sie und trennt, der Spieler endet mit `ByeReason.version` („Der Spielleiter hat eine neuere/ältere Version“). Tests in `player_link_test.dart`.
  - **Sicherheit:** Die Nachricht enthält nur die Versionsnummer, ist auf 64 Byte begrenzt und wird streng geprüft. Ein Angreifer dazwischen könnte sie fälschen und damit die Verbindung beenden. Das kann er aber ohnehin (er kappt sie einfach). Es gehen keine Daten und kein Zustand über.
- [x] **A3 Ablenkungstext „erledigt“ verständlich machen.** Wer nachts keine Aufgabe hat, sieht heute einen Ablenkungstext mit „erledigt“, das verwirrt. Er braucht einen Text, der für alle gleich aussieht und nichts behauptet (Anti-Tell). (erledigt: „Alles ruhig. Augen zu, bis das Dorf erwacht.“)
- [x] **A4 Traumpunkte nur mit Schafen.** Traumpunkte erscheinen nur, wenn das Schäfchenzählen an ist. (gab es schon: Traumpunkte nur mit `sheepInPlay`, auch am Ende)
- [x] **A5 Schloss auf den gesperrten Karten der Stichwahl.** Wer nicht in der Stichwahl steht, bekommt ein kleines Schloss, nicht nur eine graue Karte. (erledigt)
- [x] **A6 „Abstimmung beenden“ mit Rückfrage.** Ein versehentlicher Tipp beendet keine Abstimmung. (erledigt)
- [x] **A7 „Doch noch reden“ während der Warnung.** In den 5 s nach „Gleich wird abgestimmt“ kann man „Wir sind so weit“ zurücknehmen. Sinkt die Zahl unter die Mehrheit, läuft die Diskussion normal weiter (Test im Host). (erledigt, Test in `host_test.dart`)
- [x] **A8 Die Diskussionsuhr beginnt nach den letzten Worten.** Heute laufen die 7 s letzte Worte schon von der Diskussionszeit ab. (erledigt: `timeLimit` gibt dem Tag nach einem Tod `lastWordsTime` dazu, Test in `settings_test.dart`)
- [x] **A9 Spielleiter-Pause auch nachts und beim Jäger.** Pause und Weiter gibt es in jeder Phase mit Uhr, also auch in der Nacht und beim Schuss des Jägers. Das ist anti-tell-sicher: Die Pause sieht für alle gleich aus und verrät keinen Schritt. (erledigt: der Host konnte es schon, jetzt auch die App mit `LeaderBar` ohne „+30 s“)
- [x] **A10 Whowolf-Nacht mindestens 25 s.** Die Mindestdauer ist für jede Nacht gleich, damit die Dauer nichts verrät. (erledigt: `togetherHuntTime` 25 s ab Beginn der Jagd, sobald alle gewählt haben, höchstens so lang wie die Nacht)
- [x] **A11 Gleich helle Aufgabenfelder in der gerufenen Nacht.** Das hervorgehobene Aufgabenfeld leuchtet heute heller als die Felder der anderen und ist so vom Nachbarn aus zu sehen. Alle Felder werden gleich hell. (erledigt: das Feld in der gerufenen Nacht leuchtet nicht mehr)
- [x] **A12 Dorfbewohner sehen in der Whowolf-Nacht dasselbe Bild wie die anderen.** Heute unterscheidet sich der Bildschirm der Dorfbewohner sichtbar (Tell). Layout und Bewegung werden gleich wie bei den Rollen mit Aufgabe. (erledigt: auch Dorfbewohner sehen zuerst dieselbe Karte mit der Deckfrage, mit Schafen beantwortet die App sie nach einer Weile selbst; geprüft mit den Screenshots aus `screens_test.dart`)
- [x] **A13 Zeiten automatisch passend zur Runde.** Statt nur des Knopfs „Passend für N Spieler“ passen sich die Zeiten von selbst an, solange der Spielleiter sie nicht von Hand geändert hat (wie bei den Rollen mit `fittedFor`). (erledigt: `GameSettings.retimed` beim Kommen und Gehen in der Lobby, neue Räume starten mit `timedFor(0)`, Voreinstellungen behalten die Zeiten des Tisches; Test in `settings_test.dart`)
- [x] **A14 Ausfälle in jeder Rolle prüfen** (offen aus Task 020): Fehlt jemand in seiner Aktion (Jäger, Hexe, Amor, Seherin, Abstimmung), läuft die Phase nach Zeit weiter. Je Rolle ein Test. (erledigt: `absent_test.dart` lässt in beiden Nachtarten jeden Schritt, die Abstimmung und den Schuss des Jägers ohne Aktion auslaufen)
- [x] **A15 Barrierefreiheit:** (erledigt: alle Bildschirme mit `TEXT_SCALE=2` gerendert, ohne Überlauf; die eingeklappte Nachtzeile stapelt sich bei großer Schrift; Karten, Schnellwahl, Rollen, Figuren, Rollenkarte und Seitenpunkte sind per Tab und Enter/Leertaste bedienbar (`Tappable`, Test `tappable_test.dart`); Countdown rot auf Bühnenschwarz hat etwa 5:1, Uhr und Karten haben Semantics-Labels)
  - Schriftgrößen folgen der Systemeinstellung, ohne dass etwas abgeschnitten wird (Test mit großer Schrift).
  - Alles ist mit der Tastatur erreichbar (Desktop, Web).
  - Die Countdown-Farbe hat genug Kontrast.
  - Semantics-Labels für Karten, Uhr und Knöpfe.

## B – Rollen bedienen

- [x] **B1 Wölfe können ihre Wahl ändern,** bis sich das Rudel einig ist. Die Kopfzeile sagt dann „Das Rudel ist wach“ statt „Nur du bist wach“. Test im Host: eine geänderte Wahl gilt, die Einigung danach auch. (erledigt: die Karte bzw. der Wach-Bildschirm bleibt offen, bis alle lebenden Wölfe dieselbe Beute nennen; die Regeln erlaubten das Umwählen schon, Test `werewolves can change their pick`)
- [x] **B2 Hexe: die richtige Hauptaktion.** Heute ist „Nichts brauen“ der große Hauptknopf. Künftig sind die Tränke die Hauptaktionen, und „Nichts brauen“ ist ein zurückhaltender Knopf. (erledigt: „Brauen“ ist erst mit einem Trank die Hauptaktion, „Nichts brauen“ ein zurückhaltender Knopf)
- [x] **B3 Bestätigungsschritt für Seherin, Abstimmung und Jäger.** Erst auswählen, dann „Bestätigen“. Danach ist die Wahl fest. Bis die Zeit abläuft, ist ein Wechsel nur bei der Abstimmung erlaubt, wie heute. (erledigt: Abstimmung „Stimme für … abgeben“, Jäger „Auf … schießen“; nachts hat jede Karte dieselbe Folge „wählen, dann Wählen“, auch Rudel und Deckfrage, damit die Seherin nicht auffällt; geprüft mit Screenshots)
- [x] **B4 Die eigene Rolle jederzeit per Halten ansehen.** Ein Knopf, den man gedrückt hält, zeigt die Rolle nur, solange man drückt. Er sieht für alle gleich aus und ist auch nachts erlaubt, aber nur verdeckt. (erledigt: `RolePeek` oben in der Leiste, gedrückt halten zeigt Figur und Rolle, ein Tipp erklärt es; Test `role_peek_test.dart`)

## C – Desktop

- [x] **C1 Die Einstellungen von der Wisch-Seite kommen ins Zahnrad.** Auf dem Handy liegen sie rechts auf einer Wisch-Seite. Auf dem Desktop öffnet das Zahnrad oben dieselben Einstellungen, in der Lobby und im Spiel. (erledigt: das Zahnrad am Startbildschirm öffnet jetzt dieselben `AppSettings` wie die Handy-Seite statt des alten Server-Dialogs; die Spieleinstellungen der Lobby sind am Desktop eine eigene Seite mit Pfeilen)
- [ ] **C2 Die Ausrichtungsregeln gelten für alle Desktop-Ansichten:**
  - Spalten stehen auf dem Bühnenboden.
  - Die Aktion steht mittig darunter.
  - Kästen sind gleich hoch und haben genug Innenabstand.
  - Figuren sind so groß, wie es die Breite erlaubt.
  - Pfeile liegen in einer eigenen Spur.

  Durchgehen: Start, Lobby, Rolle, Nacht (jede Rolle), Morgen, Tag, Abstimmung, Stichwahl, Jäger, Ende, Einstellungen, Dialoge. Für jede Ansicht ein Screenshot auf breit und schmal.

## D – Schneller Wiederbeitritt

- [ ] **D1 Wer kurz geht und wiederkommt, braucht keine neue Bestätigung.** Nach dem Verlassen merkt sich das Gerät den Raumschlüssel und sein Token für einige Stunden (wie die 12 h im Browser). Kommt es zurück, sitzt es ohne Prüfbild und ohne Zulassen wieder an seinem Platz.
  - **Sicherheit:** Der Schlüssel und das Token liegen nur im sicheren Speicher (`flutter_secure_storage`, im Browser wie heute 12 h im `localStorage`). Sie laufen nach Zeit ab, und mit dem Raum verfallen sie. Ein Token geht nie über einen ungeprüften Kanal (das gilt heute schon). Der Spielleiter kann einen Platz weiter entfernen, dann gilt auch der gespeicherte Schlüssel nicht mehr. Test: Wiederbeitritt ohne Prüfbild klappt, nach Ablauf oder nach dem Entfernen nicht mehr.

## E – Der Erzähler gleitet (das große Stück)

Ziel des Eigentümers: Die Stimme spielt auf den Geräten gleichzeitig. Die Übergänge wirken magisch, als glitte die Stimme sauber hinüber, nicht „hier an, da aus“. Gemessen wird nichts, es zählt nur die Sitzreihenfolge. Grundlage sind die Berichte der Erzähler- und der Theater-Teams (2026-10-28).

**Baut auf Task 021 auf:** Der Plan hängt an `phaseAt` = `showAt` (vorher vereinbarter Phasenwechsel) und verteilt sich über die `voices`-Liste des Hosts (verbunden, in den letzten 7 s gehört, nicht stumm). Fällt ein Gerät aus, übernehmen die anderen den Rest des Plans. Keine eigene Liste der Sprecher mehr neben `voices`.

- [ ] **E1 Die Aufnahmen an Pausen teilen.** `tool/voice` erkennt mit ffmpeg `silencedetect` Pausen ab 180–250 ms und schreibt die Abschnitte in das Manifest (Start und Ende je Abschnitt). Außerdem werden die Aufnahmen auf −20 LUFS normalisiert und mit einem Hochpass bei etwa 200 Hz gefiltert.
- [ ] **E2 Die Abspiel-Engine entscheiden.** `flutter_soloud` (MIT) blendet und plant auf dem Audio-Thread, statt alle 40 ms die Lautstärke zu stufen. Das ist eine neue Abhängigkeit: Maintainer, Lizenz und Aktivität prüfen und in DECISIONS festhalten. Die Alternative sind feinere Blenden mit `audioplayers`. Erst ein Prototyp auf 2–3 Geräten.
- [ ] **E3 Gleiten statt Springen.** Nach dem Design des Theater-Teams:
  - Während eines Satzes bleibt die Stimme stehen.
  - 0,8–1,5 s vor einer Pause beginnt das Zielhandy mit dem Raumanteil (−40 → −18 dB).
  - Die trockene Stimme wechselt nur in Pausen ab 250 ms, mit einer Raised-Cosine-Blende von 60–120 ms und höchstens 150 ms Überlappung.
  - Das abgebende Handy blendet mit einem Tiefpass von 8 kHz auf 1,2 kHz aus.
  - Der Raumanteil blendet mit gleicher Leistung. Überlappt die trockene Stimme, liegen mindestens 12–18 dB zwischen beiden.
  - Immer ist ein Handy fast voll laut.
  - Test: Der Planer setzt Wechsel nur auf Abschnittsgrenzen.
- [ ] **E4 Schritte zwischen den Sätzen.** Die Schritt-Klänge liegen schon da (`assets/sounds/steps/`). Geschwindigkeit 1,2–3 Schritte pro Sekunde, etwa 10 dB unter der Stimme, nachts nie.
- [ ] **E5 Nachts ein fester Platz.** Alle Rufe in der Nacht kommen von derselben „Mondposition“, damit kein Weg etwas verrät.
- [ ] **E6 Hingehen nur zu Öffentlichem, mit Täuschung.** Zu einem öffentlich Toten oder Verurteilten geht die Stimme nur in 40–50 % der Fälle, dazu kommen Scheinwege zu anderen. Test: Über viele Runden verrät die Häufigkeit nichts.
- [ ] **E7 Einstellung „Bühne“: Ruhig / Lebendig / Theater.** Sie legt fest, wie viel gegangen wird (Ruhig: fast stehend, Theater: mit Schritten und Wegen). Das ist eine Spieleinstellung im Protokoll.

## F – Neue Inhalte

- [ ] **F1 Ruhemodus am Tisch** (ROADMAP 6d). Erst ein kurzes Konzept, dann ein Schritt beim Beitritt:
  - iOS: Anleitung für einen Fokus „Spieleabend“ per Kurzbefehl-Automation und für den geführten Zugriff.
  - Android: „Nicht stören“ direkt aus der App, nach der Erlaubnis des Nutzers, sonst Bildschirm anheften.
  - Freiwillig, jederzeit abschaltbar und nur auf dem eigenen Gerät.
  - **Sicherheit:** Die Berechtigung für „Nicht stören“ (Android `ACCESS_NOTIFICATION_POLICY`) ist neu. Die App fragt nur bei Bedarf und stellt den alten Zustand am Ende wieder her. Datenschutzerklärung prüfen.
- [ ] **F2 Bürgermeister** (optionale Rolle bzw. Einstellung): Am ersten Tag wählt das Dorf einen Bürgermeister. Seine Stimme zählt doppelt, oder er entscheidet bei Gleichstand (das klärt das Konzept). Stirbt er, bestimmt er einen Nachfolger. Alle Regeln liegen nur in `game_core`, die Texte sind eigene. Tests spielen ganze Partien.
- [ ] **F3 Beschützer** (neue Rolle): Er schützt jede Nacht eine Person vor den Werwölfen, nicht zweimal hintereinander dieselbe. Regeln in `game_core`, eigener Name und Text.
  - **Wartet auf neue Sprachaufnahmen des Eigentümers** (Weck- und Schlafsatz des Beschützers, eventuell Sätze für den Bürgermeister). Ich bereite die Satzliste vor, den ElevenLabs-Schlüssel setzt nur der Eigentümer.
  - Bis die Aufnahmen da sind, läuft die Rolle mit Text.
- [ ] **F4 Erzählersätze für F2 und F3** ins Skript und ins Manifest, sobald die Aufnahmen da sind.

## G – Abschluss

- [ ] **G1 Release 0.2.0.** CHANGELOG, Web-App-Build in `server/webapps.lock`, alle Geräte auf Protokoll 12.
- [ ] **G2 Generalprobe am Tisch** mit echten Geräten: iPhone, Android, Mac, ein Browser über play.whowolf.de und einer im WLAN, einer über den Code aus Task 022. Dabei werden auch die offenen Geräteprüfungen aus Task 017, 018 und 019 abgehakt.
