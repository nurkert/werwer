# Task 001 – Monorepo-Grundgerüst + `game_core`

**Status:** erledigt (2026-10-25). Abweichungen: Spielstart ab 3 Spielern (siehe DECISIONS.md); `PhaseTimeout` gilt auch am Tag; Sitzordnung = Reihenfolge der Spielerliste.
**Roadmap:** M0 (Fundament) + M1 (Spielregeln)

## Ziel

Am Ende gibt es ein Dart-Workspace-Monorepo mit dem Paket `packages/game_core`, das eine komplette Whowolf-Partie mit **Dorfbewohner, Werwolf und Seherin** regelkonform abbilden kann, vollständig getestet und ohne UI oder Netzwerk.

`app/` (M3), `packages/protocol` und `packages/game_host` (M2) werden in diesem Task **noch nicht** angelegt, `server/` erst nach dem MVP.

## 1. Monorepo-Gerüst

- Root-`pubspec.yaml` als Dart-Workspace (`workspace: [packages/game_core]`), `publish_to: none`, SDK `^3.12.0`.
- Root-`analysis_options.yaml` mit `very_good_analysis` + strikten Analyzer-Optionen (siehe `CLAUDE.md`).
- `packages/game_core/` mit `resolution: workspace`, Package-Name `game_core`, `lib/game_core.dart` als einziger öffentlicher Einstiegspunkt, Implementierung unter `lib/src/`.
- `.gitignore` ist schon da, bei Bedarf ergänzen.
- GitHub Actions: `dart analyze`, `dart format --set-exit-if-changed .` und `dart test` bei jedem Push und Pull Request.

## 2. Fachliches Modell

Alles **immutable** (finale Felder, `copyWith` wo nötig). Für Varianten `sealed class` / `enum` nutzen.

- **`PlayerId`**: stabile ID (String-Wrapper oder Extension Type).
- **`Player`**: `id`, `name`, `role`, `isAlive`.
- **`Faction`**: `village`, `werewolves`.
- **`Role`**: `villager`, `werewolf`, `seer` (enum mit `faction`). Neue Rollen sollen später ohne Umbau der Zustandsmaschine dazukommen können. Die Nachtaktionen also pro Rolle kapseln, nicht als großes `switch` überall.
- **`GameSettings`**: z. B. `revealRoleOnDeath` (Standard `true`), `seerSeesRole` (Standard `true`, sonst nur das Lager), später mehr.
- **`GameState`**: Spieler, Phase, Nummer der Runde/Nacht, gesammelte Nachtaktionen/Stimmen der aktuellen Phase, Sieger (falls beendet), Ergebnisse der Seherin.

## 3. Ablauf (Zustandsmaschine)

```
lobby → roleReveal → night → day → vote → night → … → ended
```

Die zentrale API ist rein funktional:

```dart
GameUpdate apply(GameState state, GameAction action);
// GameUpdate = neuer GameState + Liste von GameEvents
// Ungültige Aktion → typisierte RuleViolation (Exception oder Result-Typ)
```

### Aktionen (`sealed class GameAction`)

| Aktion | Erlaubt in | Wirkung |
|---|---|---|
| `AddPlayer` / `RemovePlayer` | lobby | Spieler verwalten |
| `StartGame(roles, random)` | lobby | Rollen zufällig verteilen (mit injiziertem `Random`) → `roleReveal` |
| `ConfirmRole(player)` | roleReveal | Wenn alle bestätigt haben → `night` |
| `WerewolfVote(wolf, target)` | night | Opfer der Werwölfe. Ziel darf kein Werwolf und muss lebendig sein |
| `SeerInspect(seer, target)` | night | Seherin sieht Rolle bzw. Lager (nur einmal pro Nacht) |
| `NightDecoy(player, target)` | night | **Anti-Tell:** Alle ohne Nachtaktion wählen ebenfalls jemanden. Hat keine Spielwirkung |
| `EndDiscussion` | day | → `vote` (Host oder Timer) |
| `CastVote(voter, target?)` | vote | Stimme abgeben, `null` = Enthaltung, Stimme änderbar bis zur Auflösung |
| `PhaseTimeout` | night, vote | Server-Timer abgelaufen: Phase mit dem aktuellen Stand auflösen |

### Regeln

- **Nacht endet**, sobald **alle lebenden** Spieler ihre Aktion abgegeben haben (Werwölfe, Seherin, alle anderen per Decoy) oder bei `PhaseTimeout`.
- **Werwolf-Opfer:** Mehrheit unter den Werwolf-Stimmen. Bei Gleichstand oder ohne Stimmen stirbt niemand.
- **Tag-Abstimmung:** Endet, wenn alle Lebenden abgestimmt haben, oder bei `PhaseTimeout`. Einfache Mehrheit der abgegebenen Stimmen (ohne Enthaltungen). Bei Gleichstand stirbt niemand.
- **Tote** können keine Aktionen mehr ausführen und nicht mehr abstimmen.
- **Siegbedingung** nach jedem Tod prüfen:
  - keine Werwölfe mehr → **Dorf** gewinnt
  - Werwölfe ≥ übrige Lebende → **Werwölfe** gewinnen
- **Rollenvorschlag:** Funktion `suggestRoles(playerCount)` für 5–20 Spieler (z. B. ca. 1 Werwolf pro 4 Spieler, ab 5 Spielern eine Seherin, Rest Dorfbewohner). Unter 5 oder über 20 → Fehler.

## 4. Ereignisse für den Erzähler

`sealed class GameEvent` mit **Zielgruppe** (öffentlich / bestimmte Spieler), z. B.:
`GameStarted`, `NightFell`, `PlayerKilled(player, role?)`, `NobodyDied`, `DayBroke`, `VotingStarted`, `PlayerEliminated(player, role?)`, `VoteTied`, `SeerResult(target, role|faction)` (nur Seherin), `GameEnded(winner)`.

Die Events enthalten **nur Daten, keine fertigen Texte**. Die Erzähltexte kommen später in der App (mehrsprachig, eigene Texte).

## 5. Spieler-Sichten (kein Informationsleck)

`PlayerView viewFor(GameState state, PlayerId viewer)` liefert nur, was dieser Spieler wissen darf:

- eigene Rolle, alle Namen + lebendig/tot
- aufgedeckte Rollen Toter (wenn `revealRoleOnDeath`)
- Werwölfe sehen die anderen Werwölfe und deren aktuelle Nachtstimmen
- Seherin sieht ihre bisherigen Ergebnisse
- **niemand** sieht fremde Rollen, fremde Nachtaktionen oder Decoys
- Tote: vorerst dieselbe eingeschränkte Sicht (Geistermodus kommt später)

Zusätzlich eine öffentliche Sicht (`publicView`), z. B. für einen geteilten Bildschirm.

## 6. Tests (Akzeptanzkriterien)

- [ ] Jede Regel aus Abschnitt 3 hat mindestens einen Test, auch die ungültigen Aktionen (falsche Phase, tote Spieler, Werwolf wählt Werwolf, Seherin zweimal …).
- [ ] Komplette Partien, durchgespielt über die öffentliche API: ein Dorf-Sieg und ein Werwolf-Sieg.
- [ ] Gleichstand bei Werwölfen und bei der Tagesabstimmung.
- [ ] `PhaseTimeout` mit unvollständigen Aktionen.
- [ ] Gleicher `Random`-Seed → identische Rollenverteilung.
- [ ] Sichten: Test, der für **jeden** Spieler sicherstellt, dass keine fremden Rollen oder Nachtaktionen enthalten sind.
- [ ] `suggestRoles` für 5–20 Spieler.
- [ ] `dart analyze` ohne Meldungen, `dart format` sauber, alle Tests grün.

## Für später mitdenken (nicht bauen, aber nicht verbauen)

- **Beitritt während der Partie:** `AddPlayer` ist vorerst nur in der Lobby erlaubt, aber Modell und Zustandsmaschine dürfen späteres Dazukommen nicht ausschließen (z. B. Spielerstatus „Zuschauer“).
- **Hinweis-Geräusche** und der **menschliche Erzähler** brauchen später zusätzliche Ereignisse bzw. eine Erzähler-Sicht. Events und Sichten so bauen, dass das ergänzbar ist.
- **Zustand serialisierbar** halten (Host speichert den Spielstand laufend).

## Bewusst nicht in diesem Task

- JSON-Serialisierung (kommt mit dem Protokoll in M2; Modelle aber so bauen, dass sie leicht serialisierbar sind)
- Weitere Rollen (Hexe, Jäger, Amor …)
- Timer, Netzwerk, UI, Erzähltexte

## Abschluss

- `docs/ROADMAP.md`: erledigte Punkte in M0/M1 abhaken.
- `docs/DECISIONS.md`: wichtige Designentscheidungen eintragen (z. B. Fehlerbehandlung, ID-Typ).
- Status oben auf **erledigt** setzen.
