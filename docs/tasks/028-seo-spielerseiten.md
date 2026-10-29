# Task 028 – Spielerseiten für die Suche

Status: umgesetzt (2026-10-29)

Leute, die heute Abend Werwolf spielen wollen, suchen nach „Werwolf Regeln“, „Werwolf Rollen“, „Werwolf ohne Spielleiter“ oder „Werwolf App“. Die Website hatte diese Inhalte schon in der Spielanleitung, aber nicht auf diese Fragen zugeschnitten, und die Startseite nannte die Begriffe in keiner Überschrift.

## Checkliste

- [x] Startseite: H1 mit Text (für Screenreader und Suchmaschinen, optisch bleibt das Logo), Titel und Beschreibung mit den Suchbegriffen, Kicker über den Abschnitten („Werwolf ohne Spielleiter“, „Die Werwolf-Rollen“ …), Rollennamen verlinken auf ihre Seiten, Linkzeilen zu Regeln, Spieleabend, Fragen und Halloween.
- [x] Neue Seiten, de und en, in der Spielanleitung (eigene Gruppen in der Seitenleiste, eigener Kicker, Blättern innerhalb der Gruppe):
  - Rund ums Spiel: Werwolf-Regeln (`/docs/werwolf-regeln/`, `/en/docs/werewolf-rules/`), Spieleabend (`/docs/spieleabend/`, `/en/docs/game-night/`), Häufige Fragen (`/docs/faq/`, `/en/docs/faq/`), Halloween (`/docs/halloween/`, `/en/docs/halloween/`)
  - Eine Seite pro Rolle: Dorfbewohner, Werwolf, Seherin, Hexe, Jäger, Amor, Bürgermeister (`/docs/rollen/<rolle>/`, `/en/docs/roles/<role>/`)
- [x] Jede neue Seite: eigener Titel (höchstens 60 Zeichen) und eigene Beschreibung (höchstens 155), Canonical, hreflang de/en/x-default, eine H1 mit dem Hauptbegriff, in der Sitemap, verlinkt von Startseite und Spielanleitung, am Ende ein Kasten „Heute Abend spielen?“ mit Download und Browser.
- [x] Strukturierte Daten: `BreadcrumbList` auf allen Seiten der Spielanleitung außer der Übersicht, `FAQPage` auf den Fragen (aus denselben Daten wie die sichtbaren Antworten). Seit 2023 zeigt Google Fragen-Snippets nur noch für Behörden und Gesundheitsseiten und HowTo gar nicht mehr; die Daten schaden nicht, der Gewinn liegt im Inhalt.
- [x] Entwicklerbereich (`/docs/dev/**`) mit `noindex, follow`, schon vorher aus der Sitemap genommen.
- [x] Alle Texte selbst geschrieben, nach den Regeln in `game_core` (keine Namen, Texte oder Begriffe kommerzieller Ausgaben, siehe LEGAL.md).
- [ ] In der Search Console des Eigentümers beobachten, wofür die Seiten gefunden werden, und Texte danach schärfen.

## Datenschutz

Die Website misst nichts: kein Tracking, keine Analyse, keine Cookies außer dem Hinweis. Wie die Seiten in der Suche abschneiden, sieht nur der Eigentümer in seiner Google Search Console (ohne Code auf der Seite, über den DNS-Eintrag).
