# Task 010 – Der wandernde Erzähler

**Status:** Entwurf (2026-10-26); die Aufnahmen liefert der Eigentümer
**Roadmap:** 0.1.2 (vorgezogen)

## Ziel

Die Erzählerstimme kommt nicht aus einem Handy, sie geht um den Tisch. Weil die Handys in Sitzordnung liegen, wird die Stimme bei einem Handy lauter, beim nächsten langsam lauter und beim vorigen leiser. Das soll so synchron sein, dass es klingt, als liefe der Erzähler wirklich im Kreis. Er kann auch gezielt zu jemandem gehen, etwa morgens zum Platz dessen, der nicht mehr aufgewacht ist. Gemeinsame Klänge wie das Morgen-Gähnen spielen dieselbe Technik und erklingen auf allen Handys im selben Augenblick.

## Die schwierigen Teile

1. **Gleiche Zeit auf allen Geräten.**
   - Jedes Handy schätzt den Versatz seiner Uhr zur Uhr des Hosts, nach dem NTP-Prinzip: Ping mit eigenem Zeitstempel, der Host antwortet mit seiner Zeit, und der Versatz ist die Host-Zeit minus die Mitte aus Senden und Empfangen.
   - Es zählen nur die Messungen mit der kürzesten Laufzeit, aus einem gleitenden Fenster. Im WLAN sind ±5–15 ms zu erwarten.
   - Der Host plant jeden Klang für einen Zeitpunkt in seiner Uhr, mindestens 300 ms in der Zukunft, damit alle rechtzeitig Bescheid wissen.
2. **Unterschiedliche Audio-Latenz.**
   - Zwischen „abspielen“ und dem Ton im Lautsprecher vergehen je nach Gerät 10 bis über 100 ms, bei Bluetooth noch mehr.
   - Stufe A ist deshalb so gebaut, dass Versatz kaum hörbar ist (siehe unten).
   - Stufe B misst die Latenz einmal pro Gerät: Ein Handy spielt einen Klick, die anderen hören über das Mikrofon mit. Das geht nur mit Zustimmung und erst später.
3. **Kein Verräter.**
   - Der Weg des Erzählers hängt nie von geheimen Dingen ab. Nachts läuft er seine feste Runde (Startplatz aus Raumcode und Runde) und nie auf die gerufene Rolle zu.
   - Gezielt geht er nur zu Öffentlichem: zum Toten am Morgen, zum Verbannten, zum Jäger, wenn dieser schießt.
4. **Namen.** Aufnahmen können keine Namen sagen. Gesprochen werden Sätze ohne Namen („Heute Nacht hat es jemanden erwischt“), der Gang zum Platz zeigt, wen es traf, und der Bildschirm nennt den Namen.

## Umsetzung in zwei Stufen

**Stufe A – Gang von Handy zu Handy (robust, zuerst).**
- **Schnitt:** Jede Aufnahme wird beim Einlesen an natürlichen Pausen in Abschnitte geschnitten (Stille erkennen, `tool/assets/`).
- **Gang:** Der Host legt einen Weg über die Plätze fest (Start, Richtung, Schritte). Abschnitt k spielt vor allem auf Platz p_k. Der Nachbar spielt denselben Abschnitt leise mit (Hüllkurven für Ein- und Ausblenden), sodass die Stimme weiterwandert.
- **Toleranz:** Den meisten Schall macht immer nur ein Handy. Ein Versatz von 20–40 ms zwischen Nachbarn klingt dann wie Raumhall, nicht wie Echo.
- **Nachricht:** Der Host schickt jedem Gerät nur seinen eigenen Teil des Plans: welche Abschnitte, ab wann (Host-Zeit) und mit welcher Lautstärkekurve. Neu im Protokoll ist `Cue` mit begrenzter Größe; die Erzählerkennung kommt aus einer festen Liste, nie Freitext.
- **Abspielen:** Die Engine braucht geringe Latenz und genaues Timing. Dafür wird `flutter_soloud` geprüft (SoLoud, MIT, alle Plattformen inkl. Web). `audioplayers` bleibt für die einfachen Klänge.

**Stufe B – stufenloses Wandern.** Alle Handys spielen die ganze Aufnahme zugleich, jedes mit seiner Lautstärkekurve nach dem Winkel zwischen Erzähler und Platz. Das braucht die Latenz-Messung, sonst klingt es nach Kammfilter.

**Ohne Aufnahmen** bleibt alles wie heute: Text auf dem Bildschirm und, falls eingeschaltet, die Systemstimme auf dem Host.

## Aufnahmen: was gebraucht wird

**Technik**
- WAV, 48 kHz, 24 Bit (16 Bit geht), mono.
- Ruhiger Raum ohne Hall, etwa 20–30 cm vom Mikrofon, gleichbleibender Abstand und Pegel.
- Spitzen nicht über −3 dBFS, keine Musik, kein Effekt, kein Nachbearbeiten. Lautheit und Schnitt machen wir.
- Pro Satz eine Datei mit 0,5 s Stille davor und danach.
- Natürliche, deutliche Pausen zwischen Satzteilen helfen beim Wandern.
- Dateiname: `<schlüssel>_<sprache>[_<variante>].wav`, z. B. `night_called_de_2.wav`.
- Zwei bis drei Varianten pro Satz machen es lebendiger (gleicher Inhalt, andere Betonung). Pflicht ist eine.

**Stil.** Ein Erzähler am Lagerfeuer, warm und ruhig, nachts leiser und geheimnisvoll, morgens heller. Nie hektisch.

**Die Sätze (Deutsch; Englisch gern zusätzlich, gleiche Schlüssel mit `_en`)**

| Schlüssel | Text |
|---|---|
| `reveal` | Die Rollen sind verteilt. Schaut euch eure Rolle an, und lasst niemanden mitschauen. |
| `night_together` | Die Nacht legt sich über das Dorf. Alle schließen die Augen … und tippen auf ihrem Handy. |
| `night_called` | Die Nacht legt sich über das Dorf. Alle schließen die Augen. |
| `wake_cupid` | Amor erwacht und verbindet zwei Menschen in Liebe. |
| `wake_wolves` | Die Werwölfe erwachen und suchen sich ein Opfer. |
| `wake_seer` | Die Seherin erwacht und blickt in eine Seele. |
| `wake_witch` | Die Hexe erwacht. Sie sieht, wen es heute Nacht treffen soll, und greift zu ihren Tränken. |
| `sleep` | Augen wieder zu. |
| `sleep_cupid` | Amor schläft wieder ein. |
| `sleep_wolves` | Die Werwölfe schlafen wieder ein. |
| `sleep_seer` | Die Seherin schläft wieder ein. |
| `sleep_witch` | Die Hexe schläft wieder ein. |
| `morning` | Die Sonne geht über dem Dorf auf. |
| `died_one` | Heute Nacht hat es jemanden erwischt. |
| `died_two` | Heute Nacht hat es gleich zwei erwischt. |
| `died_none` | Alle sind wieder aufgewacht. Niemand ist gestorben. |
| `role_villager` | Die Rolle war: Dorfbewohner. |
| `role_werewolf` | Die Rolle war: Werwolf. |
| `role_seer` | Die Rolle war: Seherin. |
| `role_witch` | Die Rolle war: Hexe. |
| `role_hunter` | Die Rolle war: Jäger. |
| `role_cupid` | Die Rolle war: Amor. |
| `discuss` | Jetzt redet: Wer ist der Werwolf? |
| `vote` | Genug geredet. Stimmt jetzt ab. |
| `voted_out` | Das Dorf hat entschieden. |
| `vote_tie` | Niemand wurde verbannt. |
| `hunter` | Der Jäger ist gefallen und legt an … |
| `hunter_spares` | Der Jäger senkt die Waffe. |
| `grief` | Vor Kummer folgt der Geliebte in den Tod. |
| `win_village` | Das Dorf hat gewonnen. Die Werwölfe sind besiegt. |
| `win_wolves` | Die Werwölfe haben gewonnen. Im Dorf ist es still geworden. |
| `win_lovers` | Die Verliebten haben gewonnen. Am Ende zählt nur die Liebe. |
| `welcome` | Willkommen am Tisch. Gleich geht es los. |

Die Texte im Spiel werden an diese Sätze angepasst, damit gesprochene und angezeigte Fassung übereinstimmen.

## Sicherheit

- **Was kann schiefgehen:**
  - Der Weg des Erzählers oder ein Klang verrät eine Rolle.
  - Ein manipulierter Host lässt Handys beliebige Audiodaten abspielen.
  - Zeitstempel werden zum Fingerabdruck.
- **Was schützt:**
  - Wege nur aus öffentlichen Daten (Raumcode, Runde, öffentliche Ereignisse), getestet wie `nightCues`.
  - `Cue` nennt nur Schlüssel aus der festen Liste und Zahlen in engen Grenzen; die Audiodaten liegen in der App. Für eigene Stimmen gilt später ein eigener Task mit Größen- und Formatgrenzen und Zustimmung pro Gerät.
  - Die Uhrzeit des Hosts ist ohnehin Teil des Spiels.
- **Welcher Test zeigt es:**
  - Weg und Plan sind reine Funktionen öffentlicher Werte.
  - Ein `Cue` mit unbekanntem Schlüssel oder Werten außerhalb der Grenzen wird abgelehnt.
  - Der Uhrabgleich konvergiert in einer simulierten Verbindung mit Jitter auf wenige Millisekunden.

## Fertig, wenn

- Mit den Aufnahmen auf vier Handys im Kreis: Die Stimme wandert hörbar, ohne Echo, und das Gähnen am Morgen kommt von allen zugleich.
- Ohne Aufnahmen ändert sich nichts gegenüber heute.
