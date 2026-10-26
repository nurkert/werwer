---
page: docsNeed
lang: de
title: Was ihr braucht
short: Was ihr braucht
description: "Was ihr für eine Runde Whowolf braucht: 3 bis 20 Leute, ein Gerät pro Person, dasselbe WLAN oder einen eigenen Server, und die App."
lead: "Ein Tisch, ein paar Leute und für jeden ein Gerät. Mehr braucht es nicht: kein Konto, keine Karten und nicht einmal Internet."
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

Wer nicht im selben WLAN ist, kann über einen **Vermittlungsserver** (Relay) dazukommen. Einen offiziellen Server gibt es noch nicht. Ihr könnt aber euren eigenen betreiben: Er steckt im Repository und startet mit einem einzigen Befehl (`docker compose up -d`). Die Adresse tragt ihr in der App unter Einstellungen bei „Server für Online-Spieler“ ein. Mehr dazu unter [Wie die App funktioniert](/docs/wie-die-app-funktioniert/).

## Gut zu wissen: Es ist eine Testversion

Die aktuellen Versionen (0.0.x) sind **Testversionen**. Eine ganze Runde lässt sich spielen, und seit 0.0.3 sind alle Verbindungen **Ende-zu-Ende-verschlüsselt**. Es kann aber noch ruckeln: Gebt uns Bescheid, wenn etwas nicht klappt. Mehr zur Sicherheit steht unter [Sicherheit & Privatsphäre](/docs/sicherheit/).
