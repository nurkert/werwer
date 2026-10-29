# Task 027 – Bürgermeisterwahl

Status: umgesetzt (2026-10-29), auf echten Geräten noch nicht gespielt

Den Bürgermeister gibt es seit Task 023 F2 als Einstellung (offene Wahl während der Diskussion, doppelte Stimme). Dieser Task macht ihn zu einem eigenen, gut bedienbaren Teil des Spiels: Die Figur „Bürgermeister“ verschwindet aus den Personas, ein sprachneutrales Zeichen markiert das Amt, und die Wahl hat ein eigenes Menü.

## Checkliste

- [x] **Persona ersetzt:** `Persona.mayor` wird `Persona.tinkerer`, der verrückte Tüftler (Kochtopf als Helm, Schutzbrille, ungleiche Socken, eine qualmende Erfindung mit Propeller). Damit bleibt es bei 20 Personas, zehn Frauen und zehn Männer. Die Figur, die drei Posen und die fünf Rollenkostüme sind mit Codex erzeugt (Prompts in `design/prompts/village_ensemble.md`, `poses.md`, `costumes.md`) und mit `tool/assets/` geschnitten: `app/assets/figures/tueftler.webp`, `poses/tueftler_{1,2,3}.webp`, `roles/tueftler_{werewolf,seer,witch,hunter,cupid}.webp`. Die Bürgermeister-Dateien sind aus `app/assets` raus und liegen nur noch als Geschichte in `design/source/`. Website und „So geht’s“ zeigen den Tüftler.
- [x] **Protokoll Version 18:** Ein Enum-Wert fällt weg; alte Spielstände und Geräte mit Version 17 werden sauber abgewiesen.
- [x] **Amtskette als Zeichen** (`app/lib/src/stage/mayor_mark.dart`): Messingkette im Bogen mit Medaillon und Stern, im Code gezeichnet, ohne Text. Unter 22 px wird die Kette ein einfaches Band, damit sie lesbar bleibt. Auf Karten steht sie auf einer kleinen runden Plakette (`MayorPlaque`) in der Ecke. Sie erscheint von selbst überall, wo Spielerkarten stehen: Sitzraster (Abstimmung, Nacht, Geister), Tischrunde, Vorhang am Ende, Chronik, Zeremonie. Für Screenreader trägt sie das Wort „Bürgermeister“.
- [x] **Wahlmenü** (`app/lib/src/game/mayor_election.dart`): Im Tag steht eine Tafel mit Kette, „Wer wird Bürgermeister?“, dem Stand („3 von 5 haben gewählt“), der eigenen Stimme und dem Knopf „Bürgermeister wählen“ (danach „Stimme ändern“, für Tote „Wahl ansehen“). Er öffnet die Wahl als Blatt von unten am Handy, als Dialog am Computer: alle Lebenden als Figurenkarten mit ihren Stimmen, darunter wer wen unterstützt (die Wahl ist offen), dann die Erklärung. Antippen, dann „Stimme für … geben“ wie bei Abstimmung und Jäger. Ist entschieden, schließt sich das Blatt von selbst.
- [x] **Zeremonie:** Sobald das Dorf gewählt hat, steht der neue Bürgermeister auf allen Geräten groß im Licht, die Kette fällt auf seine Schultern, dazu ein Jubel auf den Lautsprechern des Tisches. Nach knapp vier Sekunden oder einem Tipp ist sie weg.
- [x] **Chronik:** Neue Art `ChronicleKind.mayor`. Die Wahl ist öffentlich, darum steht sie schon während des Spiels in der Chronik, auch ohne offene Abstimmung.
- [x] Tests: Regeln (Chronik-Eintrag während des Spiels, keine Persona „mayor“, 20 eindeutige Personas), Protokoll (Hin und Rück für Tüftler und Chronik, unbekannte Persona wird abgewiesen), App (Kette in allen Größen mit Label, Zeremonie schließt sich, ganze Wahl bei 320, 390 und 1280 px ohne Überlauf).
- [ ] Am Tisch mit echten Geräten spielen (gehört zur Generalprobe).
- [ ] Erzählersatz `mayor` einsprechen (steht seit Task 024 im Skript).

## Regeln

Unverändert gegenüber Task 023 F2. Einzige Ergänzung: Die Wahl landet in der Chronik.

## Sicherheit und Anti-Tell

- **Was schiefgehen kann:** Das Zeichen oder die Zeremonie könnten etwas über Rollen verraten; ein Gerät mit alter Version könnte eine unbekannte Persona falsch lesen.
- **Was das verhindert:** Wer Bürgermeister ist, ist öffentlich und hängt an keiner Rolle; Zeichen, Zeremonie und Jubel sind auf allen Geräten gleich. Die Chronik zeigt während des Spiels nur die Wahl, sonst nichts Neues. Die Identität beim Wählen kommt wie immer aus der Sitzung (`MayorIntent` trägt nur das Ziel). Version 18 lehnt Geräte mit 17 ab, und der Decoder weist unbekannte Personas als `ProtocolError` ab.
- **Welcher Test es zeigt:** `packages/game_core/test/mayor_test.dart` (Chronik für alle gleich), `packages/protocol/test/chronicle_codec_test.dart` (unbekannte Persona), `app/test/mayor_election_test.dart`.
