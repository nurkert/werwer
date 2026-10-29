---
page: docsHow
lang: de
title: Wie die App funktioniert
short: Wie die App funktioniert
description: "Wie Whowolf funktioniert, einfach erklärt: Ein Handy ist Gastgeber, die anderen verbinden sich im WLAN, ein Server bringt Mitspieler von außen dazu."
lead: "Bei Whowolf ist ein Handy am Tisch der Spielleiter, ganz ohne Rechenzentrum und Cloud. Hier steht in einfachen Worten, wie das funktioniert."
figure: lauscherin
---

## Ein Handy ist der Gastgeber

Wer den Raum eröffnet, macht sein Gerät zum **Gastgeber**. Auf ihm läuft die eigentliche Partie: Es verteilt die Rollen, sammelt die Nachtaktionen und Stimmen ein, wendet die Regeln an und verkündet das Ergebnis. Alle anderen Geräte verbinden sich über das WLAN mit ihm.

Der Gastgeber ist trotzdem ein ganz normaler Mitspieler. Seine App verbindet sich genauso mit der Partie wie alle anderen und bekommt nur seine eigene Sicht. Er kann also nicht mehr sehen, nur weil das Spiel auf seinem Handy läuft.

## Wie die anderen hineinkommen

- **Räume in der Nähe:** Der Gastgeber kündigt seinen Raum im WLAN an, und die anderen Apps finden ihn von selbst.
- **QR-Code:** Der Code ist ein Link auf whowolf.de, in dem die Adresse des Gastgebers im WLAN und der Raumcode stecken. Die Whowolf-App liest ihn direkt. Mit der normalen Kamera gescannt öffnet sich eine Seite, die erklärt, wie es weitergeht. Die Angaben aus dem Link verlassen dabei euren Browser nicht.
- **Von Hand:** Adresse und Raumcode eintippen, falls nichts anderes klappt.

## Jeder sieht nur seinen Teil

Der Gastgeber schickt nie den ganzen Spielstand herum, sondern baut für jeden Spieler eine eigene, gefilterte Sicht: deine Rolle, dein Rudel, deine Blicke als Seherin, dazu alles, was ohnehin alle wissen. Was du nicht wissen darfst, kommt auf deinem Gerät gar nicht erst an.

## Wenn die Verbindung abreißt

Jedes Gerät bekommt beim Beitritt einen geheimen Sitzungsschlüssel und speichert ihn sicher. Bricht die Verbindung ab, weil der Bildschirm ausgeht oder das WLAN hakt, meldet sich die App damit wieder an und ist mit genau ihrer Rolle zurück. Das klappt sogar nach einem Neustart der App. Der Gastgeber sichert außerdem laufend den Spielstand, sodass eine Runde auch einen Absturz oder einen Neustart seiner App übersteht.

## Mitspieler von außen: der Vermittlungsserver

Wer nicht im selben WLAN sitzt, kann über einen **Vermittlungsserver** (Relay) mitspielen:

1. Der Gastgeber baut eine Verbindung zum Server auf.
2. Mitspieler von außen verbinden sich mit demselben Server über einen Online-Code.
3. Der Server reicht die Nachrichten nur weiter. Er kennt keine Spielregeln und führt keinen Spielstand.

Spieler am Tisch bleiben dabei direkt im WLAN verbunden, die anderen kommen über den Server dazu. Für die Partie macht das keinen Unterschied.

Die App nutzt dafür von sich aus den offiziellen Server `wss://play.whowolf.de`, den der Projektinhaber betreibt. Er reicht nur Ende-zu-Ende verschlüsselte Nachrichten weiter und kann sie nicht lesen. Wer das nicht möchte, wählt in den Einstellungen „Kein Online-Server (nur WLAN)“; dann geht nichts an einen Server, und mitspielen kann nur, wer im selben WLAN ist.

Ihr könnt auch **einen eigenen Server** betreiben. Was er braucht und wie ihr ihn einrichtet, steht in der [Anleitung im Repository](https://github.com/nurkert/whowolf/tree/main/server/deploy). Seine Adresse tragt ihr in der App unter Einstellungen bei „Server für Online-Spieler“ ein (sie beginnt mit `ws://` oder `wss://`).

## Eine Codebasis für alles

Whowolf ist komplett in Dart und Flutter geschrieben. Dieselbe App läuft auf iPhone, Android, Mac, Windows und Linux. Die Spielregeln stehen an genau einer Stelle und werden automatisch getestet, damit jede Runde gleich fair abläuft.

## Was noch kommt

- **Im Browser mitspielen**, ohne etwas zu installieren, einfach per QR-Code.
- **Synchrone Geräusche** auf allen Handys für die Wolfsspur, gesteuert vom Gastgeber.

Wer es ganz genau wissen will, findet die Pläne im Bereich [Für Entwickler](/docs/dev/).
