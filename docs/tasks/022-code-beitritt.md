# Task 022 – Mitspielen per Code auf play.whowolf.de

**Status:** umgesetzt (2026-10-28), offen ist die Prüfung auf echten Geräten mit dem nächsten Release
**Bezug:** Task 017 (Browser übers Netz), `packages/protocol/lib/src/relay.dart`, `server/lib/relay_server.dart`, `packages/game_host/lib/relay.dart`, `app/lib/src/net/hosted_room.dart`, `app/lib/src/game/lobby_invite.dart`, `app/lib/src/web_join_screen.dart`

## Wunsch

Wer keine funktionierende Kamera hat oder am Computer sitzt, soll trotzdem im Browser mitspielen: `https://play.whowolf.de/` öffnen, einen kurzen Code aus der Einladung eintippen, und man landet im richtigen Raum.

## Umsetzung

- **Türcode:** Ist der Raum auf einem Server, der die Web-App für diese Version hat, fragt der Host den Server nach einem **Türcode**. Er hat 6 Zeichen aus dem Relay-Alphabet ohne Verwechsler (rund 887 Millionen Möglichkeiten). Der Server würfelt ihn selbst, eindeutig. Alle 5 Minuten fragt der Host nach einem neuen. Ein Code gilt 7 Minuten, der vorige also noch kurz weiter; mehr als zwei hält ein Raum nie.
- **Relay-Protokoll** (weiter `rv: 1`, abwärtskompatibel): `RoomOpened` trägt `doors: true`, wenn der Server Türcodes vergibt (nur mit Web-App). Ältere Apps übersehen das Feld, ältere Server lassen es weg, und nur dann fragt die App. Der Host fragt mit `ask` (Raumcode, Protokollversion, Build), der Server antwortet mit `door` (Code und Gültigkeit). Alle Felder werden streng geprüft. Ein kaputter Frame beendet den Raum wie jeder andere. Fragt ein Host schneller als einmal pro Minute, antwortet der Server nicht.
- **Codeseite:** `GET /` zeigt ein Feld (de/en nach `Accept-Language`), ohne Skript und ohne fremde Quellen. `GET /c?code=…` normalisiert die Eingabe (Groß/klein, Leerzeichen, Bindestrich egal) und leitet mit 303 weiter auf `/v/<Protokoll>/<Build>/join?room=…&relay=…`. Ohne passenden Build kommt ein klarer Versionshinweis, bei unbekanntem oder abgelaufenem Code ein Hinweis mit neuem Feld.
- **Web-App:** Die Seite ohne Fragment liest nur die Web-App, mit `JoinLink.tryParseCodePage`. Ein gescannter Code geht weiter durch `tryParse`, das einen Server ohne Schlüssel nie annimmt. Der Beitritt läuft wie der Beitritt ohne QR-Code in der App: Handshake mit Commitment, beide Bildschirme zeigen das Prüfbild, die Spielleitung lässt herein. Danach kommen mit dem Welcome Schlüssel und Raumgeheimnis, und erst dann merkt sich der Browser den Raum (für Neuladen und Wiederverbinden).
- **Einladung:** Unter dem QR-Code des Servers steht „Ohne Kamera oder am Computer: auf play.whowolf.de diesen Code eingeben“ und der Code groß (`ABC 234`). Wechselt er, zieht die Anzeige nach; läuft er ab, verschwindet er. Beim WLAN-Code einer Runde ohne Internet steht kein Türcode.

## Sicherheit

- **Was kann schiefgehen?**
  - Jemand rät Codes und gelangt in fremde Runden.
  - Jemand flutet den Server mit Anfragen.
  - Der Server (oder ein Angreifer dazwischen) bietet einen falschen Raum an.
  - Codes oder Räume landen im Log.
- **Was schützt dagegen?**
  - Ein Code öffnet nichts von selbst: Er führt nur zur Seite des Raums, **ohne** Schlüssel und Raumgeheimnis. Wer so kommt, ist ein Beitritt ohne QR-Code. Prüfbild (16 Bit, nur online zu raten, höchstens 12 Versuche pro Minute am Host), Bestätigung der Spielleitung, höchstens 6 Wartende, nur in der Lobby.
  - Raten: höchstens 10 Versuche pro Adresse und Minute (`MAX_DOOR_LOOKUPS_PER_MINUTE`), richtig oder falsch. Bei 300 Räumen mit je 2 Codes trifft ein Versuch mit 1 zu 1,5 Millionen. Codes leben 7 Minuten und sterben mit ihrem Raum.
  - Der Server bekommt keine neuen Geheimnisse: Er kennt Raum-ID und Raumcode ohnehin. Schlüssel und Raumgeheimnis bleiben im Fragment des QR-Codes und gehen nie an ihn.
  - Strenge Eingabe: Code höchstens 32 Zeichen vor dem Normalisieren, danach genau 6 aus dem Alphabet. Frames mit festem Muster und Längen. Nur GET/HEAD. Nichts aus der Anfrage erscheint in der Antwort.
  - Seiten mit `default-src 'none'`, `form-action 'self'`, `frame-ancestors 'none'`, `no-store`, `nosniff`, `no-referrer`.
  - Das Relay schreibt weiter nichts ins Log, auch keine Codes.
- **Welche Tests?**
  - `server/test/door_test.dart`: Code führt zur Seite ohne Schlüssel; Rotation; der vorige Code gilt noch, ältere nicht; Ablauf; Codes sterben mit dem Raum; ohne Web-App keine Codes; fehlender Build; Rate-Limit auch für den richtigen Code; seltsame Eingaben werden abgelehnt und nie zurückgegeben; zu häufiges oder kaputtes Fragen; strenges Lesen der Frames.
  - `packages/protocol/test/link_test.dart`: Code-Seite ohne Schlüssel nur dort; ein gescannter Server-Link ohne Schlüssel bleibt abgelehnt.
  - `app/test/door_code_test.dart`: Die Einladung zeigt den Code und seine Wechsel, ohne Seite oder Browser-Weg keinen.

## Offen

- Auf echten Geräten prüfen, sobald Server und App diese Version haben.
- Beitritt per Code geht wie jeder Beitritt ohne QR-Code nur in der Lobby. Mitten im Spiel hilft weiter die Platzübergabe per QR-Code.
