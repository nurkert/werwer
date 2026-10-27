# Design – „Mondbühne“

> Der Stil für **alles**: App, Website, Store-Bilder, Social Media. Referenz: [`design/reference/mondbuehne.jpg`](../design/reference/mondbuehne.jpg).
> Stand: 2026-10-27. Die App folgt dem Bühnenbild aus Task 012, die Website noch dem Programmheft (Angleichung in Phase 7).

![Mondbühne](../design/reference/mondbuehne.jpg)

## Leitidee

Whowolf ist ein **Puppentheater bei Mondlicht**. Jede Partie ist eine Vorstellung, die Spieler sind das Ensemble, die App ist die Bühne mit Erzähler.

- **Alles ist eine flache Pappfigur:** Figuren, Häuser, Bäume, Requisiten und auch die Hintergrundebenen. Jedes Stück hat einen hellen **Kartonrand**. Die Figuren **stehen frei**, ohne Stab (seit 2026-10-25).
- **2,5D durch Ebenen:** Die Pappstücke stehen hintereinander. Scrollen verschiebt die Ebenen unterschiedlich stark. Es gibt nie echtes 3D.
- **Cartoon der 2000er, aber edel:** kräftige Konturen, ausdrucksstarke Gesichter, warmes Bühnenlicht.
- **Halb gruselig, halb verschmitzt:** Der Werwolf grinst, die Dorfbewohner schauen nervös, die Laternenträgerin weiß mehr, als sie sagt.
- **Laute Illustration, leise Oberfläche:** Die Bühne gehört den großen Momenten, die Bedienung ist ruhig und präzise.

## Das Bühnenmodell (Website-Startbild)

Von hinten nach vorn, jede Ebene ein eigenes Pappstück (`design/source/stage/ebene_*.png`, Requisiten in `design/source/props/`). Der Faktor sagt, wie stark eine Ebene beim Wegscrollen zurückbleibt (mehr = weiter hinten).

| Ebene | Inhalt | Faktor |
|---|---|---|
| Himmel | gemalter Nachthimmel mit Sternen | 0,55 |
| Mond | Pappscheibe | 0,50 |
| Wolken | drei Pappwolken (auf dem Handy eine) | 0,46 |
| Berge | Bergkette mit Burg als Streifen | 0,42 |
| Hügel | bewaldete Hügel als Streifen | 0,36 |
| Wiese | Wiese, auf der Dorf und Kirche stehen | 0,30 |
| Hinterkulisse | Kirche, Häuser, Tannen | 0,30 |
| Mittelkulisse | Steine, Büsche, Zaun | 0,18 |
| Figuren | Puppen und zwei Papp-Handys | 0,07 |

Bei `prefers-reduced-motion` bewegt sich nichts.

## Bewegung

**Grundsatz:** wie echte Puppen, nicht wie digitale Animation. Kurze, leicht federnde Kurven, höchstens eine größere Bewegung gleichzeitig.

- **Wippen:** Figuren kippen leicht um ihren Fußpunkt.
- **Auftritt:** Figuren gleiten seitlich herein oder kommen von unten hoch.
- **Wellpappe und Wenden:** Jede Figur ist auf Wellpappe geklebt (gut ein Dreißigstel ihrer Höhe dick): Von der Seite sieht man helle Deckschicht, gewellte Mittellage und Deckschicht, hinten braune Kraftpappe mit Whowolf-Stempel. Die Figuren wiegen sich leicht um ihre Hochachse, damit die Dicke immer zu sehen ist; auf der Website schwenken Rollenfiguren beim Antippen zur Seite (nie auf den Rücken). Beim Aufdecken der Rolle dreht sich die eigene Figur ganz um. Puppen, die sich in der Startbild-Geschichte umdrehen, um in die andere Richtung zu schauen, sind beidseitig bedruckt. Umsetzung: App `TurningFigure` (jede Schicht in echter Tiefe, von hinten nach vorn gezeichnet), Website `CardboardFigure.astro` (CSS 3D, Wellenlagen als phasenverschobene Streifen).
- **Startbild-Geschichte:** Die fünf Szenen spielen einmal beim Laden ab (gut 4 Sekunden), unabhängig vom Scrollen.
- **Schriftzug:** Der große Whowolf-Schriftzug wandert beim Scrollen in den Header und wird dort zum Logo.
- **Bühnenmoment (App):** Bei jedem Phasenwechsel erscheint kurz eine Bühnenkarte: Mond bei Nacht, Sonne am Tag, Waage zur Abstimmung, Pokal am Ende. Ein Tipp schließt sie; bei reduzierter Bewegung entfällt sie.
- **Schäfchen:** hüpfen über die Wiese und springen über den Zaun.

## Die App: das Bühnenbild (seit 2026-10-27, Task 012)

![Konzept](../design/reference/ui_concept_v1.png)

Die App folgt dem freigegebenen Codex-Konzept und den Konzepttafeln in `design/reference/boards/`. Jeder Moment des Abends ist **ein beleuchtetes Bühnenbild bei Mondlicht**. Die Bedienung liegt ruhig davor.

- **Szenen** (`app/lib/src/stage/scene.dart`): Die Szene folgt der Phase, also nur öffentlichen Werten.
  - Dorf am Abend: Start, Beitreten, Lobby.
  - Theater: Rolle.
  - Nachtsee: Nacht.
  - Morgen: Tag.
  - Dämmerung: Abstimmung.
  - Waldrand: Jäger.
  - Finale: Dorf; Werwölfe in der rot eingefärbten Dämmerung; Liebe am rosa See.
  - Hinter der Bühne: Datenschutz.
  - Vorhang: Warten, Verbindung.
- **Ebenen**, jede in eigener Tiefe:
  - das gemalte Bühnenbild (`app/assets/stage/*.webp`, ohne Mond);
  - der Mond als eigenes Widget;
  - die Kulissen (`app/assets/stage/scenery/`, `Scenery`): Pappstücke im Stil der Figuren mit hellem Kartonrand, sichtbarer Pappkante und Schatten auf dem Bühnenbild. Sie stehen unten an den Seiten, hängen von oben herab (Äste, Vorhänge) oder laufen quer über den oberen Rand (Lichterkette, Volant). Jede Szene hat ihre eigene Komposition von hinten nach vorn;
  - eine Abdunkelung oben und unten für Titel und Knöpfe.
  - Auf Handys und Tablets verschieben sich die Ebenen beim Neigen (`StageTilt`, `sensors_plus`): die Kulissen am stärksten, das Bild kaum. Bei reduzierter Bewegung steht alles still.
- **Responsiv:**
  - Handys spielen nur hochkant.
  - Bühnenbilder sind quadratisch und füllen jedes Format, der Boden bleibt im Bild.
  - Wie viele Kulissen stehen, richtet sich nach der Breite: auf dem Handy die vorderen, ab Tablet und Desktop weitere dahinter. Seitliche Stücke ragen höchstens ein Drittel der Breite hinein, Vorhänge höchstens 22 %. Obere Stücke kacheln, statt sich zu strecken.
  - Auf breiten Fenstern steht der Mond kleiner und hoch zwischen den Spalten.
- **Der Mond** (`Moon`) ist das Leitmotiv und hat eine Aufgabe:
  - Er zeigt die Tageszeit: Sichel, halb, voll, Blutmond, Sonne.
  - Als **Mond-Uhr** zeigt er die Zeit am Tag, bei der Abstimmung und für Aufgerufene.
  - Nachts läuft sein Ring für alle gleich aus Schrittbeginn und Nachtlänge, nie als Restzeit (Anti-Tell, siehe SECURITY_DESIGN).
- **Aufbau jedes Bildschirms:**
  - oben eine Dachzeile in Kapitälchen zwischen Strichen („— SPIELABEND —“) und darunter der Titel;
  - in der Mitte Szene, Figuren und Plaketten;
  - unten genau eine Hauptaktion, die beim Scrollen stehen bleibt (`PhaseBody.action`).

## Farben

**Eine Quelle:** [`design/tokens.json`](../design/tokens.json). `dart run tool/tokens.dart` erzeugt daraus die CSS-Variablen der Website (`website/src/styles/tokens.css`) und die Flutter-Palette (`app/lib/src/palette.g.dart`). `tool/check.sh` schlägt fehl, wenn eins davon veraltet ist.

Die App nutzt die **`stage-*`-Farben**, gemessen am Konzept. Die Website übernimmt sie in Phase 7.

| Token | Verwendung |
|---|---|
| `stage-night` … `stage-night-4`, `stage-ink` | Nachtgrund, Flächen |
| `stage-plaque`, `stage-brass`, `stage-brass-light`, `stage-brass-dark` | Plaketten: warmschwarz, doppelte Messingkante |
| `stage-ivory`, `stage-ivory-soft`, `stage-moonlight` | Titel, Text, Mondlicht |
| `stage-lantern-top`, `stage-lantern`, `stage-lantern-bottom`, `stage-lantern-ink` | Hauptknopf im Laternenverlauf und seine Schrift |
| `stage-curtain`, `stage-blood`, `curtain-400` | Vorhang, Blutmond, Tod und Gefahr |
| `stage-dusk`, `stage-dawn` | Dämmerung |

Die älteren Tokens (`night-*`, `moon-*`, `paper`, `ink`, `lantern-*`, `gold-500` …) tragen die Website und die Papierkarte am Morgen.

## Logo und Schrift

- **Logo:** handgeletterter Schriftzug „Whowolf“ als Pappfigur (Wolfsohren am „W“, Mondsichel im „o“, „wolf“ in Vorhangrot) plus rundes **Emblem** (Werwolfkopf vor dem Vollmond) für App-Icon, Favicon und kleine Flächen. Dateien: `design/source/brand/`.
- **Schrift:** **Ancizar Serif** in App und Website (variabel, 400–700) für Titel, Dachzeilen, Knöpfe, Namen, Erzählerzeile und Zahlen. **Manrope** für längeren Text. Beide SIL OFL, mitgeliefert, nichts von fremden Servern.

## App: Kernkomponenten

- **`Headline`**: Titel in der Serife mit weichem Schatten, optional mit Dachzeile (`eyebrow`).
- **`Panel`**: dunkle Plakette (`PlaqueDecoration`), halbtransparent, doppelte Messingkante, Schatten. `highlight` lässt die Kante laternenorange leuchten. Mit `paper` wird sie zur cremefarbenen Papierkarte mit goldener Doppellinie, für Nachrichten am Morgen.
- **`PrimaryButton`**: Laternenverlauf mit dunkler Kante und Glanzlinie, Beschriftung in der Serife, Symbol rechts. Gibt beim Drücken nach.
- **`SecondaryButton`**: Plakette mit Messingrand, Symbol links.
- **`PuppetCard`**: Spieler als Karte, das Brustbild der Figur auf dunklem Karton, darunter ein Namensschild, Messinghäkchen bei Auswahl. Tote sind grau und tragen den Stempel „tot“. Eingesetzt in allen Wahlen (`SeatGrid`) und am Tisch (`TableCircle`).
- **Dorf-Posen**: Jede der 20 Figuren hat drei Posen in ihrem Beruf (`app/assets/figures/poses/`, Gesichtslage in `poses.g.dart`). Die Karten wählen die Pose aus Runde, Phase und Platz (`poseFor`). In der Lobby wechselt sie alle 25 Sekunden, nachts steht die Grundfigur.
- **`Countdown`**: die Mond-Uhr.
- **Erzählerzeile**: Plakette mit Mond und kursiver Serife.
- **`GhostPanel`**: Geisterblick zum Gedrückthalten. Die Bühne Toter trägt einen kühlen blauen Schleier.
- **Ende**: Verbeugung aller Figuren in ihren Rollenkostümen.
- **Sheets und Dialoge**: warmschwarz mit Messingkante. Dazu gibt es „So geht's“ in fünf Schritten.
- **`TurningFigure`**: die Pappfigur in echtem 3D (siehe Bewegung), Referenz `design/reference/boards/board_f.png`.
- **Prüfzeichen, Schäfchenwiese, Türzeichen**: wie bisher, im neuen Stil.

## Figuren-Regeln

- Klare Silhouette, auch klein als Porträt erkennbar.
- Kräftige dunkle Kontur, gleichmäßiger heller Kartonrand, **kein Stab**.
- **Alle Figuren schauen nach rechts.** Gewendet schauen sie nach links.
- Figuren dienen als **Personas** (Aussehen der Spieler) und als Illustration der Rollen. Persona-Namen sind bewusst andere als die Rollennamen (z. B. „Laternenträgerin“, „Grauwolf“).
- **Komplett eigene Designs.** Keine Anlehnung an bestehende Serien, Spiele oder Figuren (siehe [LEGAL.md](LEGAL.md)).

## Asset-Pipeline

- **Erzeugung** mit der Codex-Bildgenerierung, immer mit Referenzbildern aus dem Projekt als Stilvorlage.
- **Sammelbögen:** mehrere Elemente pro Bild auf transparentem Hintergrund (spart Kontingent und hält den Stil einheitlich), dann mit `tool/assets/slice_sheet.py` ausschneiden und mit `clean_alpha.py` säubern. Kulissen entstehen als ein Stück pro Bild in voller Auflösung, `tool/assets/scenery.py` stellt sie frei (auch von einem gemalten Hintergrund) und schreibt ihre Seitenverhältnisse. Die Dorf-Posen schneidet `tool/assets/poses.py` und schreibt die Gesichtslage.
- **Prompts versioniert** in `design/prompts/`, Herkunft in `design/CREDITS.md`, in die Bilder eingebettet.
- **Ordner:** `design/reference/` (Stilreferenzen), `design/source/` (Originale), `design/sheets/` (Sammelbögen); optimiert (AVIF/WebP) in Website und App (`app/assets/figures`, `app/assets/sheep`).

## Offene Punkte

- Website an das Bühnenbild angleichen, mit echten App-Screenshots (Task 012, Phase 7).
