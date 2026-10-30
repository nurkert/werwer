---
page: docsNeed
lang: de
title: Was ihr braucht
short: Was ihr braucht
description: "Was ihr für eine Runde Whowolf braucht: 3 bis 20 Leute, ein Gerät pro Person mit der App oder einem Browser, dasselbe WLAN oder Internet über den Server."
lead: "Ein Tisch, ein paar Leute und für jeden ein Gerät. Ein Konto, Karten oder auch nur Internet braucht ihr nicht."
figure: dorfbewohner
---

## Leute

Whowolf startet ab **3 Spielern**, damit ihr auch zu zweit oder dritt ausprobieren könnt, wie alles funktioniert. Richtig spannend wird es ab etwa **5 Spielern**, bis zu **20** passen in einen Raum. Einen Spielleiter braucht ihr nicht, denn alle spielen mit.

## Ein Gerät pro Person

Jeder braucht ein eigenes Gerät: ein Handy, ein Tablet oder ein Laptop, mit der Whowolf-App oder einfach im Browser. Den Raum eröffnet immer jemand mit der App.

| Gerät | Voraussetzung | Stand |
|---|---|---|
| iPhone und iPad | iOS 15 oder neuer | im Browser (Safari) oder als App über [AltStore oder SideStore](/download/) |
| Android | Android 7 oder neuer | APK zum Herunterladen |
| Mac | macOS 12 oder neuer | Disk-Image (.dmg) |
| Windows | Windows 10 oder 11, 64 Bit | Installer oder ZIP ohne Installation |
| Linux | jede gängige Distribution, 64 Bit | .deb, .rpm, Flatpak, AppImage oder Archiv |

Alle Downloads und die Installationsschritte stehen auf der [Download-Seite](/download/). Den QR-Code scannen können iPhone, Android und Mac; an Windows- und Linux-Geräten tretet ihr über „Räume in der Nähe“ oder von Hand bei.

## Im Browser mitspielen

Wer nichts installieren mag, spielt im Browser mit: Der Spielleiter zeigt in seiner Einladung den QR-Code, ihr scannt ihn mit der Kamera, gebt euren Namen ein und sitzt am Tisch. Im selben WLAN kommt die Seite direkt von seinem Handy, sonst von play.whowolf.de. Beim ersten Mal lädt sie etwa 5 MB.

Damit der Abend klappt:

- **Ein aktueller Browser:** Safari, Chrome, Firefox oder Edge in einer neuen Version.
- **Ton an:** Der Erzähler und die Klänge kommen auch aus eurem Gerät. Schaltet den Stummschalter aus und dreht die Lautstärke auf.
- **Bildschirm an:** Lasst die Seite offen und im Vordergrund. Geht das Gerät in den Ruhezustand, verpasst ihr vielleicht euren Zug; ein Neuladen bringt euch an euren Platz zurück.
- **Am Tisch, nicht aus der Ferne:** Whowolf ist ein Spiel für Leute, die zusammensitzen. Über das Internet mitzuspielen ist für die da, die am Tisch kein WLAN haben, nicht als Ersatz für den Spieleabend.

Der Browser kann keinen Raum eröffnen; dafür braucht eine Person am Tisch die App.

## Dasselbe WLAN

Am einfachsten sind alle im **selben WLAN**, zum Beispiel zu Hause. Internet braucht ihr dafür nicht: Die Geräte sprechen direkt miteinander, und eure Partie verlässt den Raum nicht.

Was ihr beim ersten Mal erlauben müsst:

- **iPhone und iPad** fragen nach dem Zugriff auf das **lokale Netzwerk**. Ohne diese Erlaubnis finden sich die Geräte nicht.
- **Mac, Windows und Linux** fragen eventuell, ob die Firewall Verbindungen zulassen darf.

Manche Gäste-WLANs, etwa in Cafés oder Hotels, lassen Geräte nicht miteinander sprechen. Dann hilft es, wenn ein Handy einen Hotspot aufmacht und alle anderen sich damit verbinden.

## Mitspieler, die nicht am Tisch sitzen

Wer nicht im selben WLAN ist, kann über einen **Vermittlungsserver** (Relay) dazukommen. Die App nutzt dafür von sich aus den offiziellen Server play.whowolf.de, der nur verschlüsselte Nachrichten weiterreicht. Standardmäßig öffnet die App den Raum dort erst, wenn der Spielleiter den QR-Code zeigt. In den Einstellungen unter „Online-Spiel“ könnt ihr ihn ganz abschalten („Kein Online-Server“) oder einen [eigenen Server](https://github.com/nurkert/whowolf/tree/main/server/deploy) eintragen. Mehr dazu unter [Wie die App funktioniert](/docs/wie-die-app-funktioniert/).

## Gut zu wissen: Es ist eine Entwickler-Beta

Whowolf ist eine **Entwickler-Beta**. Eine ganze Runde lässt sich spielen, und alle Verbindungen sind **Ende-zu-Ende-verschlüsselt**. Trotzdem gilt:

- **Rechnet mit Fehlern.** Runden können hängen bleiben oder abbrechen.
- **Alle brauchen dieselbe Version.** Neue Versionen passen oft nicht zu alten; aktualisiert vor dem Spieleabend alle Geräte.
- **Spielt mit Leuten, denen ihr vertraut.** Ein unabhängiger Sicherheits-Review steht noch aus.

Gebt uns Bescheid, wenn etwas nicht klappt: [Fehler melden](https://github.com/nurkert/whowolf/issues). Mehr zur Sicherheit steht unter [Sicherheit & Privatsphäre](/docs/sicherheit/).
