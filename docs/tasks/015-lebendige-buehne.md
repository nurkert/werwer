# Task 015 – Die lebendige Bühne

**Status:** in Arbeit (2026-10-27)
**Bezug:** [Task 012](012-buehnenbild-neu.md)

Rückmeldung des Eigentümers: App und Website wirken noch „recht tot“. Gewünscht ist mehr Liebe zum Detail: Licht, das glüht und atmet (ruhig bei Fenstern, unruhiger bei Flammen), Glühwürmchen, funkelnde Sterne und Sternschnuppen über dem Titel, schimmernde Spiegelungen im Wasser, ein echter Vollmond am Himmel. Seine Beispiele sind abstrahiert und auf alle Szenen übertragen, dazu eigene Ideen, alles mit wenig Laufzeitaufwand.

## Grundlage: wo das Licht ist

`tool/assets/lights.py` findet in jedem Bühnenbild die gemalten Lichter (warm, deutlich heller als die Umgebung, je Szene nur in sinnvollen Bereichen gesucht), die Sterne über der Horizontlinie und die Lichtspiegelungen im Wasser; Laternen der Kulissenteile und einzelne Laternen der Bühnenbilder sind von Hand gesetzt. Ergebnis: `app/lib/src/stage/lights.g.dart` und `website/src/data/lights.json`. Die Positionen sind Bruchteile des Bildes, App und Website rechnen sie auf den gezeigten Ausschnitt um (wie das Bild: „cover“, beim Wischen mitschwenkend).

## Was sich bewegt, je Szene

| Szene | Licht | Leben |
|---|---|---|
| Dorf (Start, Lobby) | jedes Fenster atmet in eigenem Takt, Spiegelungen im See schimmern | Sterne funkeln, ab und zu eine Sternschnuppe über dem Titel, Glühwürmchen über der Wiese |
| Theater (Rolle) | Rampenlichter flackern sacht, Fenster des Dorfs im Hintergrund atmen | Staub tanzt im warmen Licht über der Bühne; der Vollmond steht hoch am Himmel statt im Berg |
| See (Nacht) | Fenster am Ufer, die Laterne flackert mit Lichtkreis | viele Sterne und Sternschnuppen, Spiegelungen schimmern, Nebel zieht über den See, Glühwürmchen im Schilf |
| Morgen (Neuigkeiten) | – (Tag) | Pollen und Samen schweben im Sonnenlicht, Frühnebel zieht durchs Tal |
| Platz (Tag, Abstimmung) | Fenster, die Lichterkette flackert | Nachtfalter umkreisen die hellsten Laternen, erste Glühwürmchen |
| Waldrand (Jäger) | die kleine Laterne flackert | Nebel im Tal, viele Glühwürmchen, Vollmond am Himmel |
| Finale (Dorf) | Fenster der Häuser | Glühwürmchen |
| Finale (Wölfe) | rot getönt | Glut steigt auf |
| Finale (Liebe) | rosa getönt | Funken treiben sanft wie Blütenstaub |
| Hinter der Bühne | Laterne flackert, die Spiegelbirnen glimmen, ab und zu flackert eine kurz | Staub im Licht |
| Vorhang (Warten) | beide Laternen flackern | Staub vor dem Vorhang |
| Kulissen (alle Szenen) | Laternen an Laternenpfahl, Ast, Eiche, Schilf, Lichterkette und das Fenster am Haus glühen und flackern | – |

## Technik

- **App:** eine Uhr pro Bühne (ein Ticker, gedrosselt auf etwa 30 Bilder pro Sekunde), ein Maler für alles Leben über dem Bühnenbild. Alle Lichtpunkte, Sterne, Glühwürmchen, Spiegelungen, Nebel und Staub werden mit einem einzigen `drawAtlas`-Aufruf aus wenigen vorbereiteten weichen Sprites gezeichnet (additiv), dazu höchstens eine Sternschnuppe. Kulissen-Laternen hängen am selben Takt. Bei „Bewegung reduzieren“ steht alles still (ein ruhiges, leuchtendes Standbild).
- **Website:** dieselben Daten, ein kleines Skript mit einem Canvas je Szene, das nur läuft, solange die Szene im Bild ist; bei `prefers-reduced-motion` ein Standbild. Kulissen-Laternen als weiche Lichtflecken per CSS.
- **Budget:** App unter 2 ms pro Bild auf dem iPhone, Website ohne Einbruch der Bildrate (gemessen).

## Prüfliste

- [x] Lichterkennung mit Vorschau geprüft (alle Bühnenbilder und Kulissen); in der App mit eingezeichneten Markierungen (`LIGHTS=1` im Szenen-Test) auf Handy, Tablet und Desktop: jeder Punkt sitzt auf seinem Fenster.
- [x] App: Leben in allen Szenen, Einzelbilder mit laufender Animation (`LIFE=1` im Szenen-Test).
- [ ] App: Bildrate auf dem iPhone gemessen.
- [x] App: reduzierte Bewegung zeigt ein ruhiges Standbild (Uhr steht bei einem leuchtenden Moment).
- [x] Theater: Vollmond hoch am Himmel.
- [x] Website: Leben in allen acht Szenen, fotografiert; Bildrate auf gedrosseltem Handy 60 fps, schlimmstes Bild 17 ms, keine Blockierzeit, JavaScript 22 KB.
- [ ] check.sh grün, gepusht, auf dem iPhone installiert.
