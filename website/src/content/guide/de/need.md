---
page: docsNeed
lang: de
title: Was ihr braucht
short: Was ihr braucht
description: "Was ihr für eine Runde Whowolf braucht: 3 bis 20 Leute, ein Gerät pro Person, dasselbe WLAN oder Internet für Mitspieler von außen, und die App."
lead: "Ein Tisch, ein paar Leute und für jeden ein Gerät. Ein Konto, Karten oder auch nur Internet braucht ihr nicht."
figure: dorfbewohner
---

## Leute

Whowolf startet ab **3 Spielern**, damit ihr auch zu zweit oder dritt ausprobieren könnt, wie alles funktioniert. Richtig spannend wird es ab etwa **5 Spielern**, bis zu **20** passen in einen Raum. Einen Spielleiter braucht ihr nicht, denn alle spielen mit.

## Ein Gerät pro Person

Jeder braucht ein eigenes Gerät mit der Whowolf-App. Das kann ein Handy sein, aber auch ein Tablet oder ein Laptop:

| Gerät | Voraussetzung | Stand |
|---|---|---|
| iPhone und iPad | iOS 15 oder neuer | über TestFlight, sobald die Einladung veröffentlicht ist |
| Android | Android 7 oder neuer | APK zum Herunterladen |
| Mac | macOS 12 oder neuer | Download |
| Windows | Windows 10 oder 11, 64 Bit | Download |
| Linux | Debian, Ubuntu oder verwandt, 64 Bit | Debian-Paket |

Alle Downloads und die Installationsschritte stehen auf der [Download-Seite](/download/). Im Browser ohne Installation mitspielen ist geplant, geht aber noch nicht. Den QR-Code scannen können iPhone, Android und Mac; an Windows- und Linux-Geräten tretet ihr über „Räume in der Nähe“ oder von Hand bei.

## Dasselbe WLAN

Am einfachsten sind alle im **selben WLAN**, zum Beispiel zu Hause. Internet braucht ihr dafür nicht: Die Geräte sprechen direkt miteinander, und eure Partie verlässt den Raum nicht.

Was ihr beim ersten Mal erlauben müsst:

- **iPhone und iPad** fragen nach dem Zugriff auf das **lokale Netzwerk**. Ohne diese Erlaubnis finden sich die Geräte nicht.
- **Mac, Windows und Linux** fragen eventuell, ob die Firewall Verbindungen zulassen darf.

Manche Gäste-WLANs, etwa in Cafés oder Hotels, lassen Geräte nicht miteinander sprechen. Dann hilft es, wenn ein Handy einen Hotspot aufmacht und alle anderen sich damit verbinden.

## Mitspieler, die nicht am Tisch sitzen

Wer nicht im selben WLAN ist, kann über einen **Vermittlungsserver** (Relay) dazukommen. Die App nutzt dafür von sich aus den offiziellen Server play.whowolf.de, der nur verschlüsselte Nachrichten weiterreicht. In den Einstellungen könnt ihr ihn abschalten („nur WLAN“) oder einen [eigenen Server](https://github.com/nurkert/whowolf/tree/main/server/deploy) eintragen. Mehr dazu unter [Wie die App funktioniert](/docs/wie-die-app-funktioniert/).

## Gut zu wissen: Es ist eine Entwickler-Beta

Whowolf ist eine **Entwickler-Beta**. Eine ganze Runde lässt sich spielen, und alle Verbindungen sind **Ende-zu-Ende-verschlüsselt**. Trotzdem gilt:

- **Rechnet mit Fehlern.** Runden können hängen bleiben oder abbrechen.
- **Alle brauchen dieselbe Version.** Neue Versionen passen oft nicht zu alten; aktualisiert vor dem Spieleabend alle Geräte.
- **Spielt mit Leuten, denen ihr vertraut.** Ein unabhängiger Sicherheits-Review steht noch aus.

Gebt uns Bescheid, wenn etwas nicht klappt: [Fehler melden](https://github.com/nurkert/whowolf/issues). Mehr zur Sicherheit steht unter [Sicherheit & Privatsphäre](/docs/sicherheit/).
