# Task 024 – Der Erzähler als Erlebnis

**Status:** Umgesetzt (2026-10-29); offen sind nur die Aufnahmen für `runoff`, `shot` und `mayor` (Eigentümer).
**Bezug:** [Task 010](010-wandernder-erzaehler.md) (wandernder Erzähler), [Task 023](023-sprint-alles-offene.md) E (Gleiten, Pausen), [NIGHT_SOUNDS](../NIGHT_SOUNDS.md), `tool/voice/README.md`

Rückmeldung des Eigentümers (2026-10-29): Zwischen den Sätzen gibt es teils lange Sprechpausen, manches ergibt grammatikalisch keinen Sinn oder es fehlt etwas. Ziel: ein Erzähler, der wie ein guter Mensch am Tisch erzählt, und der einfach funktioniert.

## Befund

Gemessen statt geraten: 400 zufällige Partien laufen durch die Regeln (alle Rollen, Bürgermeister, Gleichstand und Stichwahl, beide Nächte). Bei jedem Bildschirmwechsel wird festgehalten, was der Erzähler auf jedem Handy sagen würde (`app/test/narration_story_test.dart`).

1. **Es fehlte etwas, oder es kam doppelt.** Der Erzähler nahm „die Toten dieser Runde“ statt „was seit dem letzten Bildschirm neu ist“. In **395 von 400** Partien ging dabei etwas schief:
   - **291-mal fehlte das Urteil oder kam doppelt.** Bei der Abstimmung, die das Spiel beendet, sagte er nicht „Das Dorf hat entschieden“, sondern gleich „An diesem Platz saß ein Werwolf“. Beim verbannten Jäger fehlte das Urteil ebenfalls. Nach dessen Schuss kam es dann ein zweites Mal.
   - **112-mal kam der Morgen doppelt oder fehlte.** Nach dem Schuss des Jägers am Morgen hieß es noch einmal „Die Sonne geht auf … Heute Nacht hat es jemanden erwischt“, obwohl der Pfeil jemanden getroffen hatte. In der Nacht, die das Spiel beendet, fehlte der Morgen ganz.
   - **93-mal kam eine Rolle doppelt** (nach dem Jägerschuss).
   - Für den Jäger kam „Hier saß der Jäger, ein letzter Schuss bleibt ihm“ und gleich danach „Bevor der Jäger geht, darf er noch einmal schießen“: zweimal dasselbe.
2. **Lange Pausen in den Aufnahmen.** Die generierten Aufnahmen halten zwischen zwei Sätzen bis zu **1,4 s** Stille (Median 0,5 s). Auf Deutsch lagen 59 Pausen über 0,8 s, auf Englisch 38. Zusammen waren das 22 s tote Luft auf Deutsch und 9 s auf Englisch.
3. **Lange Wege.** Zwischen zwei Sätzen ging der Erzähler bis zum halben Tisch, mit 450 ms je Schritt. Bei acht Handys waren das über 2 s Schritte statt eines Atemzugs.
4. **Verschluckte Sätze.** Ein Clip, der zu seinem Zeitpunkt noch nicht geladen war (erstes Abspielen, langsamer Browser), blieb stumm. Übrig blieb ein halber Gedanke, etwa „Schließt eure Augen wieder.“, ohne dass jemand gerufen wurde.
5. **Nichts zum Bürgermeister, zum Pfeil und zur Stichwahl.** Für die Wahl und den Schuss gab es keine Sätze. Die Stichwahl steht im Skript, ist aber nie aufgenommen worden.
6. **Wolfszahl:** „Die Werwölfe erwachen“ richtete sich nach der eingestellten Zahl, nicht nach der wirklich verteilten (der Tisch kann weniger halten).
7. **Rückfrage aus `table_test.dart`** (Nacht erst nach über 30 s): Das liegt nicht am Erzähler. Der Test tippt während des Intros auf die Figur, und dort dreht sie sich noch nicht um. „Verstanden“ bleibt deshalb aus, und die Nacht kommt erst nach `revealTime` (90 s). Der Test muss warten, bis „Tippe, um deine Rolle zu sehen“ erscheint, oder das Intro überspringen. Gewollt sind 10 bis 20 s Intro und danach „Die Rollen sind verteilt“.

## Umgesetzt

- [x] **Neu statt „der Runde“:** `newDeaths(before, after)` erzählt jeden Tod genau einmal. Die Reihenfolge ist fest: der Morgen nach einer Nacht (mit „niemand / jemand / zwei“), das Urteil nach einer Abstimmung, dann jeder neue Tod für sich (Kummer, der Pfeil des Jägers) und was die Toten waren. Ein Jäger, der gleich schießt, wird nur einmal genannt, über die Jäger-Zeile. Dieselbe Regel gilt für die Zeile auf dem Bildschirm (`narration`).
- [x] **Ende:** Das letzte Urteil kommt vor dem Sieg, die letzte Nacht mit ihrem Morgen.
- [x] **Pausen in den Aufnahmen gekürzt:** `encode.py` kürzt jede Stille über 700 ms auf 700 ms und schneidet dabei die Mitte heraus. Alle Aufnahmen sind neu kodiert, die Pausen im Manifest neu gemessen. Der Test lässt keine Pause über 0,8 s zu.
- [x] **Atem wie ein Mensch** (`WalkingNarrator.gap`):
  - 650 ms innerhalb eines Gedankens, 850 ms, wenn die Geschichte weitergeht
  - 1,1 s vor einer Todesnachricht, dort fällt die Trommel hinein
  - 1,8 s, damit sich die Augen schließen, bevor eine Rolle gerufen wird
  - 1,5 s Luft anhalten vor dem Ende
- [x] **Kurze Wege:** zwei oder drei Plätze in beide Richtungen, 380 ms je Schritt. Kein Abstand zwischen zwei Sätzen liegt unter 0,6 s oder über 2 s; der Test prüft das für eine ganze Partie mit den echten Aufnahmen und acht Handys.
- [x] **Nie ein halber Satz:**
  - Ein Clip, der noch lädt, beginnt bis zu 600 ms später, statt zu fehlen. Die Pausen sind länger, also überlappt nichts.
  - In der App werden alle Aufnahmen der Sprache schon in der Lobby geladen. Im Browser geschieht das nicht, um mobile Daten zu sparen.
- [x] **Nichts abgeschnitten:** Was mitten in einer Phase dazukommt (der Bürgermeister ist gewählt), wartet, bis der laufende Satz zu Ende ist. Es beginnt ab jetzt und nicht ab dem Phasenbeginn, der schon vorbei ist (`restartsClock`, `queued`).
- [x] **Neue Momente** im Skript, je fünf Varianten auf Deutsch und Englisch, `recording_*.md` neu erzeugt:
  - `shot`: der Pfeil des Jägers, der Erzähler geht zum Getroffenen
  - `mayor`: die Kette wechselt den Platz, der Erzähler geht zum Bürgermeister
- [x] **Wolfszahl und Hexe** richten sich nach den Rollen, die der Tisch wirklich hat (`fittedFor`). Das steht öffentlich in der Lobby.
- [x] **Tests:**
  - `narration_story_test.dart`: 400 Partien prüfen, dass jeder Tod genau einmal erzählt wird, jede Nacht einen Morgen hat und jede Abstimmung ein Urteil, und dass jedes Handy dasselbe sagt.
  - Der Zeitplan ohne tote Luft.
  - Jeder Moment hat eine Aufnahme oder steht auf der Warteliste.
  - Dazu Einzeltests für Jäger, Ende, Bürgermeister, späten Start und das Warten.

## Offen

- [ ] Aufnahmen für `runoff`, `shot` und `mayor` (Eigentümer: `recording_de.md` / `recording_en.md`, dann `verify.py` und `encode.py`). Bis dahin bleiben diese Momente als Ganzes still, der Bildschirm zeigt sie.
- [ ] Am Tisch anhören (zusammen mit der Generalprobe, Task 023 G2).

## Sicherheit und Anti-Tell

- Kein neuer Netz- oder Speicherweg. Das Vorladen liest nur die gebündelten Aufnahmen der App in den Audio-Cache.
- **Anti-Tell:** Was der Erzähler sagt, ergibt sich nur aus der öffentlichen Sicht. Der Test prüft bei jedem Bildschirmwechsel jeder Partie, dass alle Handys dasselbe sagen. Pausen, Wege und Varianten hängen nur an Raum, Runde und Moment. Ein später Start hängt nur am Laden, nie an einer Rolle. Gerufene Schritte toter Rollen werden weiter gerufen.
- **Fehlertoleranz:** Neue Phasen zählen weiter ab dem gemeinsamen Start (`showAt`), und die Liste der Sprecher kommt vom Host. Nur Sätze innerhalb einer Phase beginnen „ab jetzt“; der Unterschied zwischen den Handys liegt dabei in der Größenordnung der Netzlaufzeit.
