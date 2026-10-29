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

## Android: fester Release-Schlüssel

Android installiert ein Update nur, wenn es mit demselben Schlüssel signiert ist wie die installierte App. Ohne festen Schlüssel signiert jeder CI-Lauf mit einem frischen Debug-Schlüssel, und jedes Update scheitert (man müsste deinstallieren). Darum signiert der Release-Workflow mit einem festen Schlüssel aus den **Repository-Secrets**, sobald es sie gibt (Schritt „Android release key“, `app/android/app/build.gradle.kts` liest die git-ignorierte `app/android/key.properties`). Ohne Secrets warnt der Lauf und signiert wie bisher mit dem Debug-Schlüssel.

1. Einmal den Schlüssel erzeugen, außerhalb des Repos: `tool/android_release_key.sh` (legt `~/whowolf-release.jks` an, 30 Jahre gültig, und zeigt das Passwort einmal an).
2. **Schlüssel und Passwort sichern**, etwa im Passwortmanager. Wer beides verliert, kann nie wieder ein Update über die installierte App spielen.
3. Secrets eintragen:

| Secret | Inhalt |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -i ~/whowolf-release.jks \| pbcopy`, dann einfügen |
| `ANDROID_KEY_ALIAS` | `whowolf` |
| `ANDROID_KEY_PASSWORD` | das Passwort aus Schritt 1 (Store und Schlüssel teilen es) |

Danach genügt ein neuer Tag. Der Build-Log zeigt den SHA-256 des Zertifikats (öffentlich), der von Release zu Release gleich bleiben muss; ist der Schlüssel eingetragen, aber die APK trotzdem debug-signiert, bricht der Lauf ab. Der SHA-256 ist auch der Wert für `ANDROID_CERT_SHA256` am Relay (App Links). **Einmalig** müssen alle, die eine debug-signierte Version haben, noch ein letztes Mal deinstallieren; ab dann gehen Updates direkt.

**Sicherheit:** Gefährlich wäre ein geleakter Schlüssel (jemand könnte „Updates“ unterschieben) oder ein verlorener (nie mehr Updates). Dagegen: Der Schlüssel liegt nur in den Secrets und im Passwortmanager des Eigentümers, nie im Repo (`.gitignore`: `*.jks`, `*.keystore`, `key.properties`; das Skript verweigert Pfade im Repo), im Runner nur in `$RUNNER_TEMP` und nur im Android-Job; GitHub maskiert die Werte im Log, ausgegeben wird nur das öffentliche Zertifikat. Die Prüfung mit `apksigner` im Release bricht ab, wenn trotz Schlüssel debug-signiert wurde. Die Secrets stehen Läufen aus Forks nicht zur Verfügung, und der Release-Workflow läuft nur auf Tags.

## Apple: TestFlight und signiertes macOS

Der Release-Workflow signiert macOS mit Developer ID, lässt es notarisieren und lädt iOS zu TestFlight hoch, sobald diese vier **Repository-Secrets** existieren (GitHub → Settings → Secrets and variables → Actions). Ohne sie baut er wie bisher unsigniert. Die Logik steckt in `tool/apple_release.sh`; Zertifikate und Profile holt Xcode selbst (cloud-verwaltet), im Repo liegt nichts davon.

1. In App Store Connect unter **Users and Access → Integrations → App Store Connect API** einen Team-Schlüssel mit der Rolle **Admin** anlegen (Developer-ID-Zertifikate darf nur Admin erzeugen) und die `.p8`-Datei herunterladen (geht nur einmal).
2. Unter **Apps** die App `de.whowolf.app` anlegen (für TestFlight nötig).
3. Secrets eintragen:

| Secret | Inhalt |
|---|---|
| `APPLE_TEAM_ID` | Team-ID (developer.apple.com → Membership) |
| `ASC_KEY_ID` | Key-ID des API-Schlüssels |
| `ASC_ISSUER_ID` | Issuer-ID (steht über der Schlüsselliste) |
| `ASC_KEY_P8_BASE64` | `base64 -i AuthKey_XXXX.p8 \| pbcopy`, dann einfügen |

Danach genügt ein neuer Tag (`v0.1.1`): macOS erscheint signiert und notarisiert im Release, iOS nach einigen Minuten Verarbeitung in TestFlight.

