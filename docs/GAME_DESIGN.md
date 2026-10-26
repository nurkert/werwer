# Game Design

> Status: erster Entwurf. Rollennamen und Texte sind noch offen und werden **selbst formuliert** (siehe [LEGAL.md](LEGAL.md)).

## Grundprinzip

Zwei Lager:

- **Dorf:** gewinnt, wenn alle Werwölfe tot sind.
- **Werwölfe:** gewinnen, wenn sie mindestens so viele sind wie die übrigen Lebenden.

Das Spiel wechselt zwischen **Nacht** (geheime Aktionen) und **Tag** (Diskussion + Abstimmung).

## Ablauf einer Partie

1. **Lobby:** Ein Spieler erstellt einen Raum und bekommt einen Raumcode + QR-Code. Die anderen treten bei (App oder Browser). Dann wird die **Sitzordnung** festgelegt und als **Tischkreis aus der eigenen Perspektive** angezeigt (man selbst unten, Nachbarn links/rechts), damit Fehler sofort auffallen (siehe [NIGHT_SOUNDS.md](NIGHT_SOUNDS.md)).
2. **Setup:** Der Host wählt die Rollen (oder einen Vorschlag passend zur Spielerzahl) und Optionen (Timer, Erzähler-Stimme …).
3. **Rollen verteilen:** Jeder sieht seine Rolle geheim auf dem eigenen Gerät und bestätigt.
4. **Nacht:**
   - Die App sagt an: „Das Dorf schläft ein …“
   - Rollen mit Nachtaktion werden der Reihe nach (oder parallel) aufgerufen und wählen ihr Ziel.
   - **Anti-Tell:** Alle anderen Spieler bekommen gleichzeitig eine Tarnaufgabe. So tippt nachts **jeder**.
   - **Tarnaufgabe „Schäfchen zählen“:** Schafe hüpfen über eine Wiese. Weiße Schafe (und Lämmer) antippen gibt einen Traumpunkt, schwarze besser springen lassen (−3). Alle Lebenden können die ganze Nacht zählen, auch Werwölfe und Seherin neben ihrer Aktion. Wichtig: Das Tipp-Muster muss dem der echten Nachtaktionen ähneln, damit niemand am Fingerspiel erkennbar ist. Assets: `design/source/sheep/`.
   - **Herden verteilt das Spiel:** Wie viele Schafe über die eigene Wiese laufen (3–30), legt `game_core` pro Spieler und Nacht fest, abgeleitet aus einem Startwert der Partie, mit Schwerpunkt auf kleinen Herden. Manche bekommen also einfach wenig Schafe. Die eigene Herdengröße kennt nur man selbst; mehr zählen als die Herde geht nicht.
   - **Wie gut habt ihr geschlafen?** Am Morgen sieht jeder, wie viele Schäfchen jeder gezählt hat. Das ist ein Hinweis zum Kombinieren (wer jagen musste, hatte weniger Zeit), aber kein Beweis, weil die Herden verschieden groß sind. Am Spielende gibt es den „Besten Träumer“.
5. **Morgen:** Die App verkündet, wer gestorben ist (und ggf. dessen Rolle, je nach Einstellung).
6. **Tag:** Freie Diskussion am Tisch, optional mit Timer. **Handys weg:** Der Bildschirm zeigt nur, wer noch lebt (und deutlich, ob man selbst noch lebt), am besten im selben **Tischkreis** wie in der Lobby, und dimmt sich. Keine Ablenkung, man soll sich anschauen.
7. **Abstimmung:** Jeder stimmt in der App ab. Bei Gleichstand gilt eine Regel (Stichwahl / niemand stirbt, einstellbar).
8. Zurück zu **4**, bis ein Lager gewinnt.
9. **Ende:** Siegerbildschirm + Story/Zusammenfassung der Partie.

## Personas

Jeder Spieler wählt in der Lobby eine Persona: zwanzig ganz normale Leute aus dem Dorf, zehn Frauen und zehn Männer (Magd, Bauer, Bäckerin, Schmied, Fischerin, Müller, Schneiderin, Spielmann, Gänsehirtin, Imker, Wirtin, Schäfer, Wäscherin, Zimmermann, Spinnerin, Schuster, Blumenmädchen, Bürgermeister, Großmutter, Großvater). Keine Persona sieht nach einer Rolle aus. Die Persona ist nur das Aussehen: Jede Persona kann jede Rolle sein, die Rolle wird geheim und zufällig verteilt. Jede Persona gibt es im Kostüm jeder Rolle; beim Aufdecken dreht sich die eigene Figur um und steht als ihre Rolle da (die Bäckerin als Werwölfin, der Schmied als Seher). Personas sind eindeutig, solange noch welche frei sind; danach dürfen sie sich wiederholen. Beim Beitritt bekommt man die erste freie Persona und kann sie in der Lobby ändern.

## Startrollen (MVP)

| Rolle (Arbeitsname) | Lager | Fähigkeit |
|---|---|---|
| Dorfbewohner | Dorf | Keine Sonderfähigkeit. |
| Werwolf | Werwölfe | Wählen nachts gemeinsam ein Opfer. Sehen sich gegenseitig. |
| Seherin | Dorf | Sieht nachts die Rolle (oder das Lager) einer Person. |

## Spätere Rollen (Ideen)

| Rolle | Fähigkeit |
|---|---|
| Hexe | Ein Heiltrank und ein Gifttrank pro Spiel. |
| Jäger | Nimmt beim Tod eine Person mit. |
| Amor | Verbindet in Nacht 1 zwei Personen. Stirbt einer, stirbt der andere. |
| Eigene Rollen | Ideen für Whowolf-eigene Rollen sammeln, das macht die App besonders. |

## Türzeichen

Bisher hätten nur Werwölfe einen Grund, ihr Display zu verbergen, und genau das Verbergen verrät sie. Deshalb zeigt nachts jedes Handy groß ein geheimes **Türzeichen** (3 von 16 Symbolen, jede Nacht neu, aus Startwert, Runde und Spieler berechnet). Hat ein Werwolf das Zeichen auf einem fremden Display erspäht, darf das Rudel **einmal pro Nacht** Person und Zeichen eintragen. Stimmt es, stirbt diese Person mit **50 %** zusätzlich zum Rudelopfer (normale Todeskette, die Hexe kann sie nicht retten); ein falsches Zeichen bewirkt nichts. Raten lohnt nicht (1 zu 4096 pro Nacht). Einstellung `doorSigns`: aus in „Klassisch“, an ab „Whowolf“.

## Wichtige Regeln für die App

- **Der Host entscheidet** (das Gerät des Spielleiters). Alle bekommen nur, was sie wissen dürfen, auch der Spielleiter selbst.
- **Timer pro Phase**, damit das Spiel nicht hängt, wenn jemand nicht reagiert. Dann gibt es eine Standardaktion oder einen Zufall.
- **Keine Vibration und keine Töne, die etwas über den Besitzer verraten.** Kein Gerät darf nachts wegen der Rolle oder Aktion seines Besitzers anders klingen oder vibrieren.
- **Erzähler und Nacht-Soundscape** (siehe unten) laufen synchron über **alle** Geräte, gesteuert vom Host.
- **Reconnect:** Wer kurz rausfliegt (Bildschirm aus, Netzwerk weg, App abgestürzt), kommt mit **genau seinem Status** zurück ins Spiel (Rolle, lebendig/tot, offene Aktion).
- **Später dazukommen:** Neue Spieler müssen auch während einer laufenden Partie beitreten können (Regel noch offen, siehe unten).
- **Spielleiter = normaler Spieler,** der den Raum aufmacht. Er hat keinen Wissensvorteil. Später soll auch der Server Spielleiter sein können (siehe ARCHITECTURE).
- **Tote Spieler** sehen optional alles (Geistermodus), dürfen aber nicht mehr abstimmen.

## Erzähler

- **Standard:** Die App erzählt (Text + Sprachausgabe, später Musik und Sounds).
- **Optional: Mensch erzählt, App zählt.** Ein Spieler übernimmt die Erzählerrolle und spielt nicht mit. Er bekommt einen Erzähler-Bildschirm mit allen Infos (wer welche Rolle hat, Nachtaktionen, was er ansagen soll), die App macht Rollen, Aktionen und Abstimmungen.

## Nacht-Soundscape (Idee)

Nachts spielen **alle Geräte** Geräusche ab, verteilt im Raum: Wind, Schritte, Heulen, knarrende Türen … Der Klang kommt „von überall“.

- Manche Geräusche bedeuten **nichts** (Atmosphäre, Ablenkung).
- Manche geben **echte Hinweise**, z. B. „Ein Heulen aus der Nähe von …“. Ob und wie viele, ist eine Spieleinstellung.
- **Anti-Tell-Regel:** Welches Gerät welches Geräusch spielt, wird vom Host zufällig bzw. nach der Hinweis-Mechanik bestimmt, **nie** direkt durch die Rolle oder Aktion des Besitzers. Ein Hinweis ist eine bewusste Spielmechanik mit Unschärfe, kein Leck.
- Die Mechanik gehört in `game_core` (welche Hinweise entstehen), das Abspielen in die App.

### Wolfsspur (optionaler Modus)

Ausgearbeitet in **[NIGHT_SOUNDS.md](NIGHT_SOUNDS.md)**. Kurz: Wählen die Werwölfe ihr Opfer, kann eine leise **Wolfsspur** auf dem Handy eines Werwolfs **oder seines Sitznachbarn** erklingen. Öffentliche Regel: *Spur bei X → auf X oder direkt daneben sitzt ein Werwolf.* Dorfbewohner wollen ihr Handy laut haben, Werwölfe leise. Das **Morgen-Gähnen** aller Handys entlarvt stumm gestellte Geräte. Weitere Spuren (z. B. Eulenspur der Seherin) halten die Balance.

## Offene Fragen

- **Später dazukommen während einer Partie:** Vorschlag: Wer mitten im Spiel beitritt, ist erst **Zuschauer** und wird zu Beginn der nächsten Nacht mit einer Rolle eingemischt (Host bestätigt), oder spielt erst die nächste Partie mit. Was ist fair?
- Wolfsspur: offene Fragen siehe [NIGHT_SOUNDS.md](NIGHT_SOUNDS.md).
- Rollen beim Tod aufdecken: Standard ja oder nein?
- Eigene Rollennamen und eine eigene Welt (Lore) für Whowolf?
- Mindest- und Maximalspielerzahl (Vorschlag: 5–20)?
