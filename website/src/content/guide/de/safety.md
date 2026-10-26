---
page: docsSafety
lang: de
title: Sicherheit & Privatsphäre
short: Sicherheit & Privatsphäre
description: "Warum Whowolf ohne Konto, Tracking und Werbung auskommt, warum niemand mehr sieht, als er darf, und was in der Testversion noch fehlt."
lead: "Bei Werwolf geht es um Geheimnisse. Deshalb ist Whowolf so gebaut, dass eure Rollen auf eurem Handy bleiben und eure Daten am Tisch. Hier steht, was das heißt und wo die Testversion noch Grenzen hat."
figure: beschuetzer
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

## Was noch fehlt (ehrlich)

Die Testversion ist **noch nicht Ende-zu-Ende-verschlüsselt**. Das heißt: Wer im selben WLAN technisch mitliest oder einen Vermittlungsserver betreibt, könnte die Nachrichten der Runde sehen, also auch Rollen. Spielt deshalb vorerst nur im eigenen WLAN oder mit eurem eigenen Server, unter Leuten, denen ihr vertraut.

Geplant ist vor dem ersten offiziellen Release:

- **Verschlüsselung jeder Verbindung** nach einem etablierten Verfahren (einem sogenannten Noise-Handshake). Der Schlüssel dafür steckt im QR-Code, den man nur am Tisch scannen kann. Wer mitlauscht, sieht dann nur Zeichensalat, auch der Server.
- **Gleicher Takt für alle:** Nachts bekommt jedes Gerät gleich viele und gleich große Nachrichten, damit nicht einmal die Menge des Datenverkehrs die Werwölfe verrät.
- **Bestätigung beim Beitritt von Hand:** Wer ohne QR-Code beitritt, muss vom Gastgeber bestätigt werden, und beide Geräte zeigen ein kurzes Prüfbild zum Vergleichen.

## Eine ehrliche Grenze

Das Gerät des Gastgebers kennt zwangsläufig alle Rollen, sonst könnte es die Runde nicht leiten. Die normale App zeigt sie ihm nicht. Wer aber eine selbst veränderte App als Gastgeber benutzt, könnte schummeln. Das ist wie beim Kartenspiel: Wer mischt, könnte gezinkt mischen. Spielt deshalb mit Leuten, denen ihr vertraut. Für später ist die Idee, dass auch ein Server die Runde leiten kann.

## Schwachstelle gefunden?

Bitte meldet Sicherheitslücken nicht öffentlich, sondern so, wie es in der [Sicherheitsrichtlinie](https://github.com/nurkert/whowolf/blob/main/SECURITY.md) beschrieben ist.
