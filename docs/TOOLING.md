# Tooling – „It just works“

> Anspruch: Wer das Repo klont oder die App öffnet, soll nicht nachdenken müssen. Ein Befehl, eine klare Meldung, kein Rätselraten. Lokal läuft genau dasselbe wie in der CI.

## Für Entwickler

### Ein Befehl pro Aufgabe

| Befehl | Was er tut |
|---|---|
| `dart pub get` | Löst den ganzen Workspace auf (im Repo-Root) |
| `tool/doctor.sh` | Prüft die Umgebung: Flutter-/Dart-Version, Xcode, Android SDK, CocoaPods. Sagt bei Problemen **genau**, was zu tun ist. |
| `tool/check.sh` | Format, Analyse, Tests, Secret-Scan. **Identisch mit der CI.** Ist das grün, ist auch die CI grün. |
| `tool/deploy_ios.sh` | Baut die App und startet sie auf dem angeschlossenen bzw. per WLAN gekoppelten iPhone, ohne Debugger-Hänger (ab M3) |
| `tool/deploy_android.sh` | Dasselbe für Android (ab M3) |

### Regeln

- **Eine Version für alle:** Flutter/Dart-Version steht in einer Datei im Repo (`.flutter-version`). CI und `tool/doctor.sh` lesen sie von dort, keine abweichenden Versionen.
- **Keine versteckten Schritte:** Was zum Bauen nötig ist, steht in einem Skript, nicht im Kopf. Skripte sind idempotent (zweimal ausführen schadet nie) und brechen beim ersten Fehler mit klarer Meldung ab (`set -euo pipefail`).
- **Verständliche Fehlermeldungen:** Jede Meldung sagt, was schiefging **und** was man tun kann.
- **Schnelles Feedback:** `tool/check.sh` soll in unter einer Minute durchlaufen. Langsames (z. B. Integrationstests auf Geräten) läuft getrennt.
- **CI = lokal:** Die GitHub-Actions-Workflows rufen nur die Skripte aus `tool/` auf. Es gibt keine Logik, die nur in YAML existiert.
- **Persönliches bleibt lokal:** Signierung, Team-ID, Geräte-IDs stehen nur in git-ignorierten Dateien (siehe `CLAUDE.md`).
- **Keine Warnungen ignorieren:** `dart analyze` muss leer sein, Tests müssen ohne Flackern grün sein.

## Für Spieler

- **Kein Konto, keine Einrichtung:** App öffnen, Namen eingeben, spielen. Server, Ports und IPs bekommt niemand zu sehen.
- **Sinnvolle Standards:** Rollenvorschlag nach Spielerzahl, Einstellungen nur, wenn man sie sucht.
- **Probleme werden erkannt, nicht nur gemeldet:** Klappt die Verbindung nicht, sagt die App warum und was hilft. Beispiele:
  - „Dein WLAN lässt Geräte nicht miteinander sprechen. Starte einen Hotspot auf dem Host-Handy.“
  - „Erlaube ‚Lokales Netzwerk‘ in den Einstellungen.“
- **Robust statt empfindlich:** Bildschirm aus, kurz kein WLAN, App aus Versehen geschlossen? Man ist automatisch wieder drin.
- **Ehrlich:** Keine Fake-Ladebalken, keine Meldung „Etwas ist schiefgelaufen“ ohne Erklärung.

## Kommandozeilen-Client

Zum Testen ohne App (M2): `packages/cli`.

```bash
dart run packages/cli/bin/whowolf.dart host Ada            # Raum eröffnen, druckt den Beitrittslink
dart run packages/cli/bin/whowolf.dart join Bo "<link>"    # verschlüsselt und verifiziert beitreten
dart run packages/cli/bin/whowolf.dart join Cem 192.168.1.5 1234   # per Adresse; der Host lässt nach Prüfcode rein
```

Befehle im Spiel: `start`, `confirm`, `pick <name>`, `vote`, `vote <name|none>`, `admit <id>`, `refuse <id>`, `again`, `table`, `quit`.
Hinweis macOS: Eine frisch kompilierte, unsignierte Binärdatei wird von der Firewall für eingehende Verbindungen still blockiert; zum Hosten `dart run` nehmen oder die Firewall-Freigabe erteilen.

## Einmalige GitHub-Einstellungen (Admin)

Repository → **Settings**:

1. **Branches → Add branch ruleset** für `main`: Pull Request oder Status-Checks verlangen, „CI / check“ und „CI / security“ als Pflicht-Checks, Force-Push und Löschen verbieten.
2. **Code security → Secret Protection:** einschalten, dazu **Push protection**.
3. **Code security → Private vulnerability reporting:** einschalten (passt zu `SECURITY.md`).
4. **Code security → Dependabot alerts** und **security updates** einschalten (die Versions-Updates kommen aus `.github/dependabot.yml`).

Neue Umgebung prüfen: `tool/doctor.sh`.
