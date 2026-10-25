# Rechtliche Hinweise

> Keine Rechtsberatung, sondern Leitlinien für das Projekt. Vor einer kommerziellen Veröffentlichung kann eine kurze anwaltliche Prüfung (Marken- und Urheberrecht) sinnvoll sein.

## Spielprinzip

- **Spielregeln und Mechaniken sind nicht urheberrechtlich geschützt.** Geschützt ist nur die konkrete Gestaltung (Texte, Grafiken, Namen/Marken).
- Werwolf/Mafia ist ein **Volksspiel**: „Mafia“ entstand 1986 in der Sowjetunion, die Werwolf-Variante kam später dazu. Beide sind frei.
- Allgemeine Rollen und Begriffe (Werwolf, Dorfbewohner, Seherin, Hexe, Jäger …) sind normale Wörter.

## Was wir **nicht** tun

- **Keine fremden Markennamen** verwenden, weder in der App noch im Namen, in Store-Texten oder in der Werbung. Beispiele:
  - „Die Werwölfe von Düsterwald“ / „Les Loups-garous de Thiercelieux“
  - „Ultimate Werewolf“, „One Night Ultimate Werewolf“
  - Namen bestehender Werwolf-Apps
- **Keine fremden Grafiken, Logos, Kartenbilder oder Regeltexte** übernehmen.
- **Keine sehr speziellen, erfundenen Rollen** einer bestimmten Edition samt Name und Beschreibung 1:1 kopieren.
- **Nicht so tun**, als wären wir eine offizielle App eines anderen Spiels.

## Was wir tun

- Alle Texte, Erzähler-Sprüche, Rollenbeschreibungen und Grafiken **selbst erstellen**.
- Eigener Name (**Lycan**) und eigene visuelle Identität.
- Assets von Dritten (Fonts, Sounds, Icons) nur mit passender Lizenz, mit Nachweis in `NOTICE` bzw. einer Credits-Datei.

## Name „Lycan“: noch zu prüfen

- [ ] DPMA-Register: https://register.dpma.de
- [ ] EUIPO (EU-Marken): https://euipo.europa.eu/eSearch
- [ ] App Store und Google Play nach gleichnamigen Apps durchsuchen
- [ ] Domain (z. B. `lycan.app`, `lycan.game`, `playlycan.com`)

„Lycan“ ist ein allgemeines Wort (von *Lykanthrop*) und wahrscheinlich schon in anderen Zusammenhängen im Einsatz. Falls nötig, nehmen wir einen Zusatz wie **„Lycan – Werewolf Party“**.

### Erste Recherche (2026-10-25, kurze Websuche, keine Registerprüfung)

| Fund | Relevanz |
|---|---|
| **Lycan Master** (App Store, LOGAMES): Erzähler-/Spielleiter-App für Werwolf | ⚠️ hoch: gleiche Nische, ähnlicher Name |
| **Lycans** (Steam, Onu Games, 2023): Social-Deduction-Werwolfspiel mit Voice-Chat | ⚠️ mittel: gleiches Genre, Plural, PC |
| Kleine itch.io-Projekte („Lycan“, „Lycan Trickery“) | gering |
| Markenregister | ungeprüft, die Websuche fand keinen Eintrag „LYCAN“ in Klasse 9/28/41 |
| Domains | `lycan.app`, `lycan.io`, `lycangame.com` vergeben; `getlycan.app` und `lycanparty.com` vermutlich frei |
| GitHub | `github.com/lycan` ist vergeben (Repo `nurkert/lycan` ist ok) |

Einschätzung: „Lycan“ allein ist nicht verbrannt, aber im Werwolf-Genre schon angekratzt. Mit einem Zusatz (z. B. „Lycan – Werewolf Party“) und eigener Optik ist es vermutlich vertretbar. Vor der Store-Veröffentlichung müssen DPMA/EUIPO/USPTO trotzdem richtig geprüft werden.

## Lizenz: Apache 2.0

Gewählt wurde die **Apache License 2.0** für das gesamte Repo:

- **Store-kompatibel.** Die GPL verträgt sich schlecht mit dem App Store (bekanntes Beispiel: VLC).
- **Permissiv** wie MIT, enthält aber zusätzlich eine **ausdrückliche Patentlizenz** und einen Schutz vor Patentklagen.
- Verlangt, dass Änderungen gekennzeichnet werden und die `NOTICE`-Datei erhalten bleibt.

Option für später: den Server unter **AGPL** stellen, damit Änderungen an öffentlich betriebenen Servern offengelegt werden müssen. Vorerst bleibt alles Apache 2.0.

**Wichtig:** Die Lizenz deckt den Code ab, nicht automatisch den Namen. Der Name „Lycan“ und das Logo können später als Marke gelten, damit Forks nicht unter demselben Namen in die Stores gehen. Dafür kann eine Trademark-Policy ergänzt werden.

## App Stores

- Datenschutzerklärung nötig, auch bei minimaler Datensammlung.
- Apple: 99 $/Jahr, iOS-Apps nur über den App Store.
- Google: 25 $ einmalig. Neue private Entwicklerkonten müssen eine Testphase mit mehreren Testern durchlaufen.
- Altersfreigabe: Werwolf hat „Töten“ als Thema, aber ohne Gewaltdarstellung. Beim Fragebogen ehrlich angeben.
