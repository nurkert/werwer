---
page: docsSafety
lang: de
title: Sicherheit & Privatsphäre
short: Sicherheit & Privatsphäre
description: "Warum Whowolf ohne Konto, Tracking und Werbung auskommt, warum niemand mehr sieht, als er darf, und was in der Testversion noch fehlt."
lead: "Bei Werwolf geht es um Geheimnisse. Deshalb ist Whowolf so gebaut, dass eure Rollen auf eurem Handy bleiben und eure Daten am Tisch. Hier steht, was das heißt und wo die Testversion noch Grenzen hat."
figure: seherin
---

## Kurz gesagt

- **Kein Konto.** Ihr gebt nur einen Namen für den Tisch ein. Keine E-Mail, keine Telefonnummer, keine Anmeldung.
- **Kein Tracking, keine Werbung.** Die App enthält keine Analyse-Werkzeuge, keine Werbung und keine Käufe. Diese Website auch nicht.
- **Eure Daten bleiben am Tisch.** Im WLAN spielen die Geräte direkt miteinander. Nichts geht an uns oder an Dritte.
- **Open Source.** Jeder kann im Quellcode nachsehen, ob das stimmt.

## Niemand sieht mehr, als er darf

Das Spiel läuft auf dem Gerät des Gastgebers. Jedes andere Gerät bekommt von dort **nur das, was sein Besitzer wissen darf**: die eigene Rolle, beim Werwolf das eigene Rudel, bei der Seherin ihre eigenen Blicke. Fremde Rollen werden gar nicht erst verschickt, auch nicht versteckt.

Das gilt auch für den Gastgeber selbst: Seine App zeigt ihm genauso nur seine eigene Sicht. Er hat keinen Vorteil, nur weil die Runde auf seinem Handy läuft.

Auch von außen soll niemand etwas erkennen: Nachts tippen alle, jeder Nacht-Bildschirm sieht ähnlich aus, und kein Handy vibriert oder klingt wegen der Rolle seines Besitzers anders.

## Was schon geschützt ist

- **Niemand kann sich als jemand anderes ausgeben.** Wer ihr seid, erkennt der Gastgeber an eurer Sitzung, nicht an dem, was eine Nachricht behauptet.
- **Rejoin nur mit eurem Schlüssel.** Jedes Gerät bekommt beim Beitritt einen zufälligen Sitzungsschlüssel, der im sicheren Speicher des Geräts liegt. Nur damit kommt man auf seinen Platz zurück.
- **Der QR-Code wird genau geprüft.** Die App folgt nur Whowolf-Links, verbindet sich im WLAN nur mit privaten Adressen und fragt vor dem Verbinden nach.
- **Der Gastgeber schützt sich selbst.** Nachrichten werden streng geprüft und sind in Größe und Menge begrenzt. Verbindungen nimmt er im WLAN nur aus dem lokalen Netz an.
- **Berechtigungen erst, wenn nötig.** Die Kamera nur zum Scannen, das lokale Netzwerk erst beim Eröffnen oder Beitreten. Kein Standort, keine Kontakte, kein Mikrofon.
- **Nachprüfbare Downloads.** Jede Version wird automatisch aus dem öffentlichen Quellcode gebaut, mit Prüfsummen und Herkunftsnachweis. Wie ihr eine Datei prüft, steht auf der [Download-Seite](/download/).

## Verschlüsselt, und zwar richtig

Seit Version 0.0.3 ist **jede Verbindung Ende-zu-Ende-verschlüsselt**, im WLAN wie über einen Vermittlungsserver. Wer mitlauscht, auch der Betreiber eines Servers, sieht nur gleich große Pakete mit Zeichensalat.

- **Mit QR-Code:** Der Code am Tisch enthält einen Schlüssel und ein Geheimnis dieses Raums. Daran erkennt eure App den echten Gastgeber, ein Betrüger im WLAN kann sich nicht dazwischenschalten.
- **Ohne QR-Code** (Raum in der Nähe gefunden oder von Hand eingegeben): Die Verbindung ist genauso verschlüsselt. Damit niemand Fremdes hereinrutscht, zeigt euer Handy vier Zeichen, und der Gastgeber lässt euch erst rein, wenn sie mit denen auf seinem Bildschirm übereinstimmen. Ab 0.0.4 kann auch niemand in der Mitte passende Zeichen erzwingen, und nach dem Reinlassen kommt ihr bei jedem Wiederverbinden über den geprüften Weg zurück.
- **Gleich große Nachrichten:** Jede Nachricht wird auf feste Größen aufgefüllt, und alle bekommen bei jeder Änderung dieselbe Menge. So verrät nicht einmal der Datenverkehr, wer nachts als Werwolf mehr zu tun hat.
- **Geprüfte Bibliothek:** Seit 0.0.4 kommt die gesamte Verschlüsselung aus [libsodium](https://doc.libsodium.org/), einer weit verbreiteten und unabhängig geprüften Bibliothek (Schlüsseltausch mit X25519, XChaCha20-Poly1305, BLAKE2b). Whowolf rechnet nichts davon selbst. Wie wir die Bausteine zusammensetzen, soll vor Version 0.1 jemand von außen prüfen.

## Eine ehrliche Grenze

Das Gerät des Gastgebers kennt zwangsläufig alle Rollen, sonst könnte es die Runde nicht leiten. Die normale App zeigt sie ihm nicht. Wer aber eine selbst veränderte App als Gastgeber benutzt, könnte schummeln. Das ist wie beim Kartenspiel: Wer mischt, könnte gezinkt mischen. Spielt deshalb mit Leuten, denen ihr vertraut. Für später ist die Idee, dass auch ein Server die Runde leiten kann.

## Schwachstelle gefunden?

Bitte meldet Sicherheitslücken nicht öffentlich, sondern so, wie es in der [Sicherheitsrichtlinie](https://github.com/nurkert/whowolf/blob/main/SECURITY.md) beschrieben ist.
