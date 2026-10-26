# Task 008 – Host-Übernahme: Nachfolger und Zeuge

**Status:** in Arbeit (2026-10-26)
**Roadmap:** 0.1.1

## Ziel

Fällt das Host-Gerät weg (App beendet, Akku leer, Gastgeber geht), übernimmt still und schnell ein anderer Spieler. Aus Sicht der Spieler gibt es nur die gewohnte kurze Pause, danach geht dieselbe Runde weiter. Der neue Host wird auch Spielleiter (Start, Einlass, Abstimmung starten, Revanche). Kommt der alte Host zurück, setzt er sich als normaler Spieler wieder an den Tisch.

Grundsätze: kein Gerät allein bekommt die Geheimnisse der Partie, nur dokumentierte libsodium-Bausteine, kein neuer offener Endpunkt, wenig zusätzlicher Verkehr.

## Idee

Der Host bestimmt laufend zwei Spieler: den **Nachfolger** (S) und den **Zeugen** (W). Kandidat ist jedes native App-Gerät, das im WLAN hosten kann, in Sitzreihenfolge; Browser und das Host-Gerät selbst nie.

- **S hält den versiegelten Raum:** nach jeder Änderung den Schnappschuss samt Raumschlüsseln, verschlüsselt mit einem Schlüssel K (secretstream, eine Nachricht mit Final-Tag).
- **W hält K** und den Kandidatenschlüssel von S, aber nie den Raum.
- Allein kann keiner von beiden etwas lesen. Wer schummeln will, braucht zwei manipulierte Geräte, die zufällig genau diese beiden Plätze haben.
- **K wechselt**, sobald S oder W wechselt. Wer seine Aufgabe verliert, bekommt die Anweisung, sein Material zu löschen.

### Übernahme

1. **S** verliert den Host länger als `takeoverAfter` (Standard 6 s). Dann öffnet S einen **Kandidaten-Eingang**: einen eigenen `SecureTransport` mit Kandidaten-Schlüsselpaar und Kandidaten-Geheimnis. S hat beides bei seinem Beitritt erzeugt und dem Host mitgeteilt; der Host gibt es nur an W weiter. Der Eingang wird per Bonjour angekündigt (Raumcode, Abdruck des Kandidatenschlüssels).
2. **W** gibt K nur heraus, wenn W den Host selbst länger als `takeoverAfter` verloren hat. Das ist die zweite, unabhängige Stimme. W verbindet sich mit dem Kandidaten-Eingang über das QR-Muster des Handshakes, also mit Schlüssel und Geheimnis, und das wirkt gegenseitig: W weiß, dass es S ist (nur S hat den privaten Schlüssel), und S weiß, dass der Gegenüber vom Host eingeweiht wurde. Dann schickt W `{epoch, K}`.
3. S entsiegelt (nur mit dem richtigen K, sonst ignoriert) und stellt den Raum mit **denselben Raumschlüsseln** und **Epoche + 1** wieder her. Danach macht S sich selbst zum Spielleiter und setzt sich über die lokale Verbindung wieder an den eigenen Platz.
4. Die übrigen Spieler suchen den Host ohnehin per Bonjour über Raumcode und Schlüsselabdruck und finden S. Ihr gespeicherter Host-Schlüssel passt, sie kehren mit ihrem Token zurück, unbestätigte Absichten werden erneut geschickt.

### Freiwilliges Gehen

Tippt der Gastgeber auf „Verlassen“, übergibt er geordnet: Er schickt S den letzten Stand und W die Freigabe, ohne auf die Wartezeit zu warten. Danach schließt er still, ohne die Partie für alle zu beenden.

### Geteilte Tische verhindern (Epochen)

- Jeder Schnappschuss trägt eine **Epoche**, jede Übernahme zählt sie hoch. Das Welcome nennt sie, Bonjour kündigt sie an.
- Spieler weisen einen Host mit kleinerer Epoche ab, als sie schon kennen, und suchen weiter.
- Ein zurückkehrender alter Host stellt nicht blind wieder her. Hört er von einer höheren Epoche, durch Bonjour oder ein Hello, prüft er sie, indem er sich mit seinem eigenen Token und seinen eigenen Raumschlüsseln dorthin verbindet. Nur ein echter Nachfolger kann diesen Handshake bestehen. Bestätigt sich die höhere Epoche, tritt er zurück und spielt als Spieler weiter. Eine bloße Behauptung in einem Hello reicht dafür nie.

## Umfang

1. `protocol`:
   - Hello mit optionalem Kandidaten (Schlüssel und Geheimnis)
   - Welcome mit Epoche
   - neue Nachrichten `Custody` (an S) und `Witness` (an W), jeweils auch als Löschanweisung
   - `Release` (W an S, nur auf dem Kandidatenkanal)
   - Größen streng begrenzt
2. `game_host`:
   - Epoche und Kandidaten im Schnappschuss
   - Auswahl von S und W und das Versiegeln über ein eingespeistes Siegel, damit `game_host` frei von sodium bleibt
   - `GameHost.takeOver` mit neuem Spielleiter
   - `PlayerLink` hält das Material, weist ältere Epochen ab und kann auf einen neuen Dialer umschalten
   - der Ablauf in reinem Dart (`Succession`) mit eingespeisten Zeitgebern und Transporten, testbar ohne Netz
3. `secure_channel`: `sealRoom` und `openRoom` (secretstream mit Final-Tag), `CandidateKeys` (HostKeys mit eigenem Zweck).
4. App:
   - Kandidaten-Eingang (LAN und Bonjour)
   - Umschalten der Sitzung auf den eigenen neuen Host
   - Rücktritt eines alten Hosts
   - geordnete Übergabe beim Verlassen
5. Tests:
   - Ganze Partien, in denen der Host mitten in der Nacht, beim Abstimmen und in der Lobby wegfällt
   - Übergabe beim Verlassen
   - Rückkehr des alten Hosts
   - Chaos-Test mit Host-Ausfall statt Neustart

## Sicherheit

- **Was kann schiefgehen:**
  - Ein manipuliertes Gerät täuscht eine Übernahme vor, um an die Rollen zu kommen.
  - Ein Fremder im WLAN gibt sich als Nachfolger aus und erschleicht K.
  - Jemand legt den Host mit einer erfundenen höheren Epoche lahm.
  - Der Kandidaten-Eingang wird geflutet.
  - Ein alter und ein neuer Host spielen parallel weiter.
- **Was schützt:**
  - Zwei unabhängige Geräte (S hat nur Chiffrat, W nur K), und W verlangt den eigenen Verbindungsverlust.
  - Gegenseitige Authentisierung über das vorhandene QR-Muster.
  - Der Eingang ist nur nach Host-Verlust offen, nimmt nur geprüfte Handshakes an (`maxHandshakes`, Zeitlimit) und schließt nach der Übernahme.
  - Eine Epoche zählt erst nach geprüftem Handshake mit den Raumschlüsseln.
  - Material wird beim Rollenwechsel gelöscht.
  - Keine Geheimnisse in Logs.
- **Restrisiko:**
  - S und W zusammen könnten den Raum lesen.
  - Nach der Übernahme ist S Host, mit demselben Vertrauen wie heute jedes Host-Gerät.
  - Bestätigte Aktionen aus den letzten Millisekunden vor einem harten Ausfall können fehlen. Der Spieler sieht das und tippt erneut.
  - Wer S ist, verrät die Größe des Verkehrs.
  - Übernahmen laufen nur im WLAN; Relay-Spieler warten wie bisher.
- **Welcher Test zeigt es:**
  - Ohne K lässt sich nichts öffnen, und ein falsches K wird ignoriert.
  - W gibt K nicht heraus, solange er den Host erreicht.
  - Ein Kandidat ohne Geheimnis kommt nicht durch den Handshake.
  - Ein Hello mit höherer Epoche lässt den Host nicht zurücktreten.
  - Ganze Partien mit Ausfall enden regelkonform, und niemand sieht fremde Geheimnisse.

## Fertig, wenn

- Die Tests oben laufen grün in `tool/check.sh`.
- Auf echten Geräten (iPhone, Mac, Android): Der Host schließt die App mitten in der Abstimmung, und innerhalb von etwa 15 s geht die Runde auf einem anderen Gerät weiter.
- DECISIONS, SECURITY_DESIGN, ARCHITECTURE und ROADMAP sind aktualisiert.
