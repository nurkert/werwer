# Design – „Mondbühne“

> Der Stil für **alles**: App, Website, Store-Bilder, Social Media. Referenz: [`design/reference/mondbuehne.jpg`](../design/reference/mondbuehne.jpg).
> Status: Stil festgelegt (2026-10-25). Farben und Schriften sind ein erster Entwurf und werden mit den ersten echten Assets geschärft.

![Mondbühne](../design/reference/mondbuehne.jpg)

## Leitidee

Whowolf ist ein **Puppentheater bei Mondlicht**. Jede Partie ist eine Vorstellung, die Spieler sind das Ensemble, die App ist die Bühne mit Erzähler.

- **Alles ist eine flache Pappfigur:** Figuren, Häuser, Bäume, Requisiten. Jede ist ein eigenes 2D-Element mit hellem **Kartonrand** und sitzt an einem **Holzstab** oder auf einem kleinen Ständer.
- **2,5D durch Ebenen:** Die Pappfiguren stehen auf hintereinander gestaffelten Ebenen. Bewegung (Scrollen, Neigen, Übergänge) verschiebt die Ebenen unterschiedlich stark. Es gibt nie echtes 3D.
- **Cartoon der 2000er, aber edel:** kräftige Konturen, ausdrucksstarke Gesichter, klare Silhouetten. Dazu warmes Bühnenlicht und hochwertige Details (Goldborten, Samt, Holzmaserung).
- **Halb gruselig, halb verschmitzt:** Der Werwolf grinst, die Dorfbewohner schauen nervös, die Seherin weiß mehr, als sie sagt.

## Das Bühnenmodell (Ebenen)

Von hinten nach vorn. Jede Ebene ist ein eigenes Asset mit transparentem Hintergrund.

| Nr. | Ebene | Inhalt | Bewegung |
|---|---|---|---|
| 0 | **Prospekt** (gemalter Hintergrund) | Nachthimmel, Mond, Sterne, ferne Berge/Burg | kaum (Parallaxe ~0,1) |
| 1 | **Hinterkulisse** | Dorf, Wald, Brücke | wenig (~0,3) |
| 2 | **Mittelkulisse** | Steine, Zäune, Büsche | mittel (~0,6) |
| 3 | **Figurenebene** | Werwolf, Seherin, Dorfbewohner | Puppenbewegung (siehe unten) |
| 4 | **Vordergrund** | Rampe, Requisiten, Fass, Bühnenkante | stark (~1,2) |
| 5 | **Rahmen** | Vorhang, Portal, Goldborte | fest (rahmt alles) |
| 6 | **Licht** | Spots, Laternenschein, Mondlicht (Overlay) | wandert, flackert |

## Bewegung

**Grundsatz:** Wie echte Puppen, nicht wie digitale Animation.

- **Wippen am Stab:** leichtes Auf und Ab bzw. Kippen um den Stabpunkt.
- **Scharniere:** Arme, Kopf, Kiefer drehen sich um einen sichtbaren Drehpunkt. Gliedmaßen sind dafür eigene Teile.
- **Auftritt/Abgang:** Figuren gleiten seitlich herein oder klappen von unten hoch.
- **Vorhang:** öffnet und schließt bei Phasenwechseln (Nacht ↔ Tag), auf der Website beim Laden.
- **Licht:** Spot wandert zur aktiven Figur, Laternen flackern dezent, der Mond tritt hinter Wolken.
- **Kurvenverläufe:** kurze, leicht federnde Kurven (wie Holz und Pappe, die nachschwingen). Nichts gleitet linear.
- **Weniger ist mehr:** Höchstens eine größere Bewegung gleichzeitig. Im Ruhezustand atmet die Bühne nur leise.
- **`prefers-reduced-motion`:** keine Parallaxe, kein Wippen, nur weiche Überblendungen.

## Farben (Entwurf)

Abgeleitet aus der Referenz. Später als Design-Tokens (eine Quelle für Website und App).

| Token | Farbe | Verwendung |
|---|---|---|
| `night-900` | `#141a33` | tiefster Hintergrund, App-Hintergrund nachts |
| `night-700` | `#232c52` | Flächen, Karten nachts |
| `night-500` | `#3a4677` | Ränder, sekundäre Flächen |
| `moon-100` | `#f6e7c1` | Mondlicht, heller Text auf Nacht |
| `lantern-400` | `#f2a93b` | **Akzent**: aktive Elemente, Hervorhebung, Laternenschein |
| `curtain-600` | `#9e1f24` | Vorhang, Gefahr, „gestorben“ |
| `gold-500` | `#c9973f` | Borten, Auszeichnungen, Sieg |
| `card-200` | `#e9d6ac` | Kartonrand, Papierflächen am Tag |
| `wood-700` | `#5a3a22` | Holz, Stäbe, dunkler Text auf Papier |
| `forest-700` | `#22382f` | Wald, Dorf-Lager |

**Regeln:**
- Nachts dominiert `night`, tags dominiert `card` (Papier).
- Der Akzent (`lantern`) wird sparsam eingesetzt. Er markiert, was man antippen soll.
- `curtain` ist für Tod und Gefahr reserviert.
- Kontraste nach WCAG AA für alle Texte.

## Logo und Schrift

- **Logo:** handgeletterter Schriftzug „Whowolf“ als Pappfigur (Wolfsohren am „W“, Mondsichel im „o“, „wolf“ in Vorhangrot) plus rundes **Emblem** (Werwolfkopf vor dem Vollmond) für App-Icon, Favicon und kleine Flächen. Dateien: `design/source/brand/`.
- **CI-Schrift für Überschriften:** **Lilita One** (SIL OFL), kräftig und rund, passend zum Logo.
- **Oberfläche und Text:** **Manrope** (SIL OFL).
- Nur frei lizenzierte Schriften (OFL); die Dateien werden mitgeliefert, nichts von Google-Servern nachgeladen (Datenschutz).

## Website: Szene statt Bühne

Auf der Website gibt es **keinen Bühnenrahmen**. Der Hero ist die nächtliche Szene (Prospekt + Kulissen + Figuren auf Ebenen). Die Figuren werden **von unten gehalten**: Ihre Stäbe laufen aus dem Bild und verschwinden in einem Verlauf ins Nachtblau. Der Vorhang bleibt ein **gelegentliches Stilmittel** (z. B. für Übergänge), nicht der Dauerrahmen.

## Oberfläche: Wie es wertig wirkt

Die Illustration ist laut, die Oberfläche ist leise. Diese Mischung macht den hochwertigen Eindruck.

- **Die Bühne gehört den großen Momenten:** Startbildschirm, Rollenenthüllung, Einbruch der Nacht, Morgen, Sieg, Website-Hero.
- **Bedienoberfläche ruhig und präzise:** wenige Farben, viel Luft, klare Hierarchie, große Tippflächen. Elemente wirken wie edle Theater-Requisiten (Programmheft, Eintrittskarte, Goldrand), aber zurückhaltend.
- **Die Rollenkarte** ist das Herzstück: Sie wird wie eine Pappfigur umgedreht bzw. hochgeklappt.
- **Tischkreis** in der Lobby und am Tag: Spieler als kleine Pappfiguren-Medaillons im Kreis.
- **Nacht:** dunkel, gedimmt, minimal, damit niemand auffällt (Anti-Tell). Die Bühne zeigt nur ein ruhiges Mondmotiv.
- **Konsistenz:** Jede Komponente existiert einmal und wird überall verwendet. Abstände, Radien und Schatten kommen aus Tokens.

## Figuren-Regeln

- Klare Silhouette, auch klein als Medaillon erkennbar.
- Kräftige dunkle Kontur, gleichmäßiger heller Kartonrand (ca. 2–3 % der Figurenhöhe), sichtbarer Stab oder Ständer.
- Warme Lichtkante von der Laterne oder dem Spot, kühles Mondlicht von hinten.
- **Komplett eigene Designs.** Keine Anlehnung an bestehende Serien, Spiele oder Figuren (siehe [LEGAL.md](LEGAL.md)).
- Jede Figur hat ein **Referenzblatt** (Vorderansicht, Ausdrücke, Teile für die Animation) in `design/characters/`.

## Asset-Pipeline

- **Erzeugung mit Codex** (Bildgenerierung), immer mit der Referenz `design/reference/mondbuehne.jpg` als Stilvorlage.
- **Prompts versioniert** in `design/prompts/`, damit jedes Asset nachvollziehbar und neu erzeugbar ist.
- **Ein Element pro Bild, transparenter Hintergrund,** Teile für Gelenke getrennt.
- **Ordner:**
  - `design/reference/`: Stilreferenzen
  - `design/characters/`: Referenzblätter
  - `design/source/`: Originale in voller Auflösung
  - von dort optimiert (AVIF/WebP/PNG) in Website und App
- **Herkunft dokumentieren:** Werkzeug, Datum, Prompt-Datei, in `design/CREDITS.md`.

## Offene Punkte

- Endgültige Schriften und Farbwerte nach den ersten Figuren-Referenzblättern.
- Tag-Variante der Bühne (Morgenlicht, Papier statt Nacht).
- Logo und App-Icon im Mondbühnen-Stil.
