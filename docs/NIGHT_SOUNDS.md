# Nachtgeräusche & Wolfsspur

> Status: Idee, ausgearbeiteter Entwurf. Optionaler Spielmodus. Alle Zahlen sind Startwerte und werden in Testrunden (und vorab per Simulation) austariert.

## Ziel

Nachts spielen die Handys auf dem Tisch leise Geräusche ab. Die meisten sind nur Atmosphäre, manche sind **Spuren**: Hinweise darauf, wo gerade jemand eine Nachtaktion ausgeführt hat. So entsteht eine Deduktionsebene **im echten Raum**, die es nur gibt, weil jeder sein eigenes Handy vor sich liegen hat.

Leitsätze:

- **Ein Verdacht, kein Beweis** – zumindest nicht für alle.
- **Dosiert, nicht nervig** – ein paar Geräusche pro Nacht, viel Stille dazwischen.
- **Spuren sind Regeln, keine Lecks** – jeder kennt die Regel, niemand kennt den Zufall.

## Die Spur-Regel (öffentlich, jeder kennt sie)

> **Ein Wolfsgeräusch auf dem Handy von X bedeutet: Auf dem Platz von X oder direkt daneben sitzt ein Werwolf.**

Wenn die Werwölfe nachts ihr Opfer wählen, kann eine **Wolfsspur** entstehen. Sie wird auf **genau einem** Handy abgespielt: entweder auf dem eines Werwolfs selbst **oder** auf dem seines linken oder rechten Sitznachbarn.

### Wer erfährt was?

| Wer | Was er weiß |
|---|---|
| Dorfbewohner, bei dem die Spur **auf dem eigenen Handy** kommt | „Einer meiner beiden Nachbarn ist ein Werwolf.“ Für ihn fast sicher (**privater Beweis**). |
| Die Sitznachbarn von X | „Bei X kam das Geräusch. X oder einer von uns beiden ist Werwolf.“ |
| Der Rest des Tisches | Vielleicht nur „da drüben hat was geknurrt“, unscharf. |
| Der Werwolf, wenn die Spur bei ihm kommt | Er muss es gut überspielen oder hatte sein Handy leise. |

Das Schöne daran: Wer die Spur auf dem eigenen Handy hört, weiß viel, ist aber für alle anderen **selbst verdächtig**, weil es ja bei ihm kam. Er muss die anderen überzeugen. Und ein Werwolf kann genau dasselbe behaupten, um seine Nachbarn zu belasten.

## Das Spannungsfeld Lautstärke

- **Dorfbewohner wollen ihr Handy laut haben,** denn nur so bekommen sie die Spuren auf ihrem eigenen Handy mit.
- **Werwölfe würden ihr Handy gern leise stellen,** damit Spuren bei ihnen selbst untergehen.
- **Aber leise stellen schützt nur halb:** Die Spur kann genauso gut beim Nachbarn landen.
- **Morgen-Gähnen:** Bei Tagesanbruch gähnt **jedes** Handy gleichzeitig mit derselben Lautstärke-Vorgabe. Ein stummes oder auffällig leises Handy fällt auf. Wer nachts leise gestellt hat, muss rechtzeitig wieder laut machen, und Herumdrücken an der Lautstärke ist selbst verdächtig.
- Die App **verrät die eingestellte Lautstärke nie**. Das Katz-und-Maus-Spiel ist die Mechanik.

## Ablauf einer Nacht (Klangdramaturgie)

1. „Das Dorf schläft ein …“ – leise Grundstimmung (Wind, Grillen) auf allen Geräten.
2. Über die Nacht verteilt **2–5 Atmosphäre-Geräusche** auf zufälligen Handys (Schritte, Eule, knarrende Tür, Rascheln). Eindeutig anders als das Wolfsgeräusch, aber geeignet, es zu überdecken.
3. **0–1 Wolfsspur** (selten 2), **zeitversetzt**: nicht genau beim Tippen der Wölfe, sondern zufällig 5–25 Sekunden nachdem sie ihr Opfer festgelegt haben. Sonst könnte man Tippen und Geräusch zusammenbringen.
4. **Überdecken:** Im Moment der Spur läuft manchmal auf dem Handy eines Nachbarn gleichzeitig ein Atmosphäre-Geräusch. Dann hört nur einer der beiden Nachbarn die Spur klar.
5. Morgen: Alle Handys gähnen. Dann die Ansage, wer gestorben ist.

## Wo landet die Spur? (Startwerte)

- Pro Nacht entsteht mit Wahrscheinlichkeit **p_spur ≈ 50 %** eine Wolfsspur.
- Ausgangspunkt ist ein zufälliger lebender Werwolf.
- Ziel-Handy: Werwolf selbst / linker Nachbar / rechter Nachbar, je **⅓** (einstellbar).
- Ist der Nachbar selbst ein Werwolf, ist das in Ordnung. Die Regel stimmt trotzdem.
- **Tote Spieler:** Vorschlag: Spuren landen nur auf Handys lebender Spieler. „Nachbar“ heißt dann „nächster lebender Nachbar“ (offene Frage).

## Weitere Spuren (Erweiterungen)

Das System ist allgemein: **Jede Nachtaktion kann eine Spur mit eigenem Geräusch hinterlassen.** In `game_core` ist das pro Rolle als Daten hinterlegt (Geräusch, Wahrscheinlichkeit, Radius).

- **Eulenspur (Seherin):** Wenn die Seherin jemanden prüft, kann ein Eulenruf auf ihrem Handy oder dem eines Nachbarn kommen. Damit haben auch die **Wölfe eine Spur**, die sie verfolgen können. Das ist das Gegengewicht zur Wolfsspur, und beide Seiten profitieren vom Hinhören.
- **Spätere Rollen:** Hexe (Blubbern eines Tranks), Beschützer (leises Klirren) usw.
- **Eigene Whowolf-Rollen**, die mit Spuren spielen:
  - **Fährtenleger** (Werwolf-Seite): darf einmal pro Spiel eine falsche Wolfsspur auf ein Handy seiner Wahl legen.
  - **Lauscher** (Dorf): hört mit größerem Radius oder bekommt morgens auf dem Bildschirm, ob in seiner Nähe eine Spur war.
  - **Stille Pfote** (Werwolf-Seite): hinterlässt nie eine Spur.

## Balance

- **Informationswert:** Bei 8 Spielern grenzt eine Spur den Werwolf auf 3 Plätze ein. Mit p_spur ≈ 50 % ist das grob „eine halbe Seherin“, aber unscharf und öffentlich umstritten.
- **Spielerzahl beachten:** Bei 5–6 Spielern deckt „X oder daneben“ die halbe Runde ab, die Spur ist also schwach. Bei 15+ Spielern ist sie stark. Die Standardwerte richten sich deshalb nach der Spielerzahl.
- **Ziel:** Die Gewinnquote der Werwölfe soll mit Spuren ungefähr gleich bleiben. Die Eulenspur gleicht aus.
- **Simulation:** `game_core` ist deterministisch und hat injizierten Zufall. Damit lassen sich vor den Testrunden tausende Partien mit einfachen Bot-Strategien simulieren, um die Startwerte abzuschätzen. Das ist nur eine grobe Näherung, echte Menschen bluffen anders.

### Stellschrauben

| Stellschraube | Wirkung |
|---|---|
| `p_spur` (pro Nacht) | Wie oft es überhaupt Hinweise gibt |
| Gewichtung Selbst / Nachbarn | Wie oft der Werwolf selbst „klingt“ |
| Anzahl Atmosphäre-Geräusche | Wie leicht Spuren überdeckt werden |
| Überdecken an/aus | Ob oft nur ein Nachbar die Spur klar hört |
| Eulenspur an/aus | Gegengewicht für die Wölfe |
| Stärke (aus / subtil / deutlich) | Voreinstellungen, die oben genannte Werte bündeln |

## Lügen und Bluffs (gewollt)

- Ein Dorfbewohner mit Spur auf dem eigenen Handy sagt: „Bei mir kam's, also ist einer von euch beiden der Wolf.“
- Ein Werwolf behauptet genau dasselbe, um zwei Unschuldige zu belasten.
- Ein Werwolf neben einer Spur zeigt sofort auf X.
- Niemand kann beweisen, was auf seinem Handy passiert ist. Das Geräusch ist der einzige gemeinsame Beleg, und der ist unscharf.

## Sitzordnung

Für die Wolfsspur **nötig**.

- In der Lobby: „Tippt nacheinander im Uhrzeigersinn auf ‚Ich‘“. Das dauert etwa 10 Sekunden. Alternativ ordnet der Spielleiter per Drag & Drop.
- Wer mitten im Spiel dazukommt oder den Platz wechselt, wird neu einsortiert.

## Technik

- **Synchrones Abspielen:** Der Host schickt „spiele Geräusch S auf Gerät D um Zeitpunkt T“. Die Geräte gleichen ihre Uhr per Ping mit dem Host ab.
- **Spuren entstehen in `game_core`** (mit injiziertem Zufall). Das Ergebnis ist ein Ereignis mit genau einem Ziel-Gerät. Abgespielt wird in der App.
- **iOS-Stummschalter:** Mit der Audio-Kategorie „Playback“ wird der Schalter ignoriert. Nur die Lautstärketasten zählen, und so soll es sein.
- **Display nach unten:** Die App bleibt im Vordergrund mit gedimmtem Bildschirm (Wakelock). Den Näherungssensor könnte man nutzen, um zu prüfen, ob das Handy umgedreht liegt.
- **Kopfhörer und Bluetooth** würden die Mechanik aushebeln. Vorschlag: Die App erkennt das und sagt morgens öffentlich an, bei wem Kopfhörer verbunden waren.
- **Browser-Spieler (wichtige Einschränkung):** Browser spielen Audio erst nach einer Interaktion ab und verstummen auf iOS bei gesperrtem Bildschirm. Spuren funktionieren dort womöglich nur eingeschränkt. Vorschlag: Browser-Spieler bekommen Spuren nur, solange ihr Gerät nachweislich abspielbereit ist, sonst wird ein anderes Handy gewählt. Die Spur-Regel bleibt dabei gültig.
- **Barrierefreiheit:** Der Modus ist abschaltbar.

## Offene Fragen

- Startwerte für `p_spur` und Gewichtung, abhängig von der Spielerzahl?
- Zählen tote Spieler als Nachbarn?
- Soll ein Werwolf auf seinem Bildschirm erfahren, dass gerade eine Spur bei ihm oder seinem Nachbarn kam? Vorschlag: nein. Wer leise gestellt hat, bekommt es eben nicht mit.
- Wie gehen wir mit Browser-Spielern um?
- Kopfhörer: öffentlich melden oder verbieten?
