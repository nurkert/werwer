# Game Design

> Status: erster Entwurf. Rollennamen und Texte sind noch offen und werden **selbst formuliert** (siehe [LEGAL.md](LEGAL.md)).

## Grundprinzip

Zwei Lager:

- **Dorf:** gewinnt, wenn alle Werwölfe tot sind.
- **Werwölfe:** gewinnen, wenn sie mindestens so viele sind wie die übrigen Lebenden.

Das Spiel wechselt zwischen **Nacht** (geheime Aktionen) und **Tag** (Diskussion + Abstimmung).

## Ablauf einer Partie

1. **Lobby:** Ein Spieler erstellt einen Raum und bekommt einen Raumcode + QR-Code. Die anderen treten bei (App oder Browser).
2. **Setup:** Der Host wählt die Rollen (oder einen Vorschlag passend zur Spielerzahl) und Optionen (Timer, Erzähler-Stimme …).
3. **Rollen verteilen:** Jeder sieht seine Rolle geheim auf dem eigenen Gerät und bestätigt.
4. **Nacht:**
   - Die App sagt an: „Das Dorf schläft ein …“
   - Rollen mit Nachtaktion werden der Reihe nach (oder parallel) aufgerufen und wählen ihr Ziel.
   - **Anti-Tell:** Alle anderen Spieler bekommen gleichzeitig eine Dummy-Aufgabe (z. B. „Wähle, wem du am wenigsten traust“). So tippt nachts **jeder**.
5. **Morgen:** Die App verkündet, wer gestorben ist (und ggf. dessen Rolle, je nach Einstellung).
6. **Tag:** Freie Diskussion am Tisch, optional mit Timer.
7. **Abstimmung:** Jeder stimmt in der App ab. Bei Gleichstand gilt eine Regel (Stichwahl / niemand stirbt, einstellbar).
8. Zurück zu **4**, bis ein Lager gewinnt.
9. **Ende:** Siegerbildschirm + Story/Zusammenfassung der Partie.

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
| Beschützer | Schützt nachts eine Person (nicht zweimal hintereinander dieselbe). |
| Eigene Rollen | Ideen für Werwer-eigene Rollen sammeln, das macht die App besonders. |

## Wichtige Regeln für die App

- **Der Server entscheidet.** Clients bekommen nur, was sie wissen dürfen.
- **Timer pro Phase**, damit das Spiel nicht hängt, wenn jemand nicht reagiert. Dann gibt es eine Standardaktion oder einen Zufall.
- **Keine Vibration, keine Töne** während der Nacht auf einzelnen Geräten. Der Erzähler läuft über ein Host-Gerät oder synchron über alle.
- **Reconnect:** Wer kurz rausfliegt (Bildschirm aus, Netzwerk weg), muss wieder in dasselbe Spiel kommen.
- **Tote Spieler** sehen optional alles (Geistermodus), dürfen aber nicht mehr abstimmen.

## Offene Fragen

- Erzähler nur auf dem Host-Gerät oder auf allen Geräten gleichzeitig?
- Rollen beim Tod aufdecken: Standard ja oder nein?
- Eigene Rollennamen und eine eigene Welt (Lore) für Werwer?
- Mindest- und Maximalspielerzahl (Vorschlag: 5–20)?
