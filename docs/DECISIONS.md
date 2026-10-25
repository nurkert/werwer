# Entscheidungen

Log der Projektentscheidungen, neueste oben.

| Datum | Entscheidung | Begründung |
|---|---|---|
| 2026-10-25 | Name **Whowolf** statt „Werwer“ | Gleiches Wortspiel („Who? Wolf“ = „Wer? Wer?“), aber international verständlich und überall gleich aussprechbar. „Werwer“ lag mit „Werw…“ nah an **Werwörter** (Ravensburger) bzw. **Werewords** (Bezier Games), beides Werwolf-Spiele mit App. Websuche fand kein Spiel/keine App „Whowolf“; Registerprüfung steht noch aus. GitHub-Repo heißt vorerst weiter `nurkert/werwer` |
| 2026-10-25 | **Start: nur Flutter-App, lokal im gleichen WLAN, ohne Server.** Ein Gerät ist Host und spielt intern die Rolle des autoritativen Servers, die anderen verbinden sich per WebSocket im LAN. So plattformübergreifend wie möglich (Android, iOS, macOS, Windows, Linux; Web nur als beitretender Client, siehe ARCHITECTURE). | Schnellster Weg zu einer spielbaren Runde am Tisch, keine Hosting-Kosten. Die Architektur bleibt so geschnitten, dass später ein echter Server **ohne Umbau** dazukommt: Host-Logik und Transport sind getrennt, das Protokoll ist dasselbe. |
| 2026-10-25 | ~~Name **Werwer**~~ (ersetzt durch Whowolf) statt „Lycan“ | Wortspiel „Wer? Wer?“ + Werwolf, einzigartig, gut verfügbar; „Lycan“ ist im Genre schon belegt („Lycan Master“, „Lycans“). Repo umbenannt in `nurkert/werwer` |
| 2026-10-25 | Doku/Wiki im Repo (`website/`), nicht im GitHub-Wiki | Versioniert, Teil von Pull Requests, im App-Style gestaltbar |
| 2026-10-25 | Server ist **autoritativ** | Kein Schummeln, Clients sehen nur ihre eigenen Infos |
| 2026-10-25 | Server in **Dart**, Regeln in gemeinsamem Paket `game_core` | Regeln nur einmal schreiben, von App und Server gemeinsam genutzt |
| 2026-10-25 | **Self-Hosting per Docker** + offizieller Server | Open-Source-Gedanke, jeder kann eigenen Server betreiben |
| 2026-10-25 | **Flutter** als primäre App, inkl. **Flutter Web** | Eine Codebasis für alle Plattformen, Beitritt im Browser ohne Installation |
| 2026-10-25 | **Monorepo** `nurkert/werwer` (öffentlich) | App, Server, Website und Doku an einem Ort |
| 2026-10-25 | Lizenz **Apache 2.0** | Store-kompatibel, permissiv, mit Patentlizenz |
| 2026-10-25 | ~~Name **Lycan**~~ (ersetzt durch Werwer) | Kurz, international, eigene Identität; Markenprüfung noch offen |
| 2026-10-25 | Konzept: vor Ort zusammen, **jeder mit eigenem Gerät**, **App als Erzähler** | Kein Spielleiter nötig, keine Tells, Regeln automatisch |
