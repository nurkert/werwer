import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/settings_controls.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/net/game_session.dart';

extension PresetText on AppLocalizations {
  String preset(Preset? preset) => switch (preset) {
    Preset.classic => presetClassic,
    Preset.whowolf => presetWhowolf,
    Preset.fullStage => presetFullStage,
    null => presetCustom,
  };

  /// The name of [settings]: a preset's, the basic game's (werewolves, seer,
  /// villagers: what a new room starts with) or "your own mix".
  String settingsName(GameSettings settings) =>
      settings == const GameSettings() ? presetBasic : preset(settings.preset);

  String presetText(Preset preset) => switch (preset) {
    Preset.classic => presetClassicText,
    Preset.whowolf => presetWhowolfText,
    Preset.fullStage => presetFullStageText,
  };

  /// "8 min", "90 s".
  String duration(Duration d) => d.inSeconds % 60 == 0 && d.inMinutes > 1
      ? minutes(d.inMinutes)
      : seconds(d.inSeconds);
}

/// The host's settings for the next game, laid out in place (the lobby's
/// settings page, task 012). Every change goes to the host at once (it
/// checks and broadcasts them), so the page always shows what the table
/// will play.
class GameSettingsPanel extends StatelessWidget {
  const GameSettingsPanel({required this.session, super.key});

  final GameSession session;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      final view = session.view;
      if (view == null) return const SizedBox.shrink();
      return _SettingsBody(
        settings: view.settings,
        players: view.seats.length,
        seats: view.seats,
        you: view.you,
        onChanged: (settings) => session.send(SettingsIntent(settings)),
      );
    },
  );
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.settings,
    required this.players,
    required this.onChanged,
    this.seats = const [],
    this.you,
  });

  final GameSettings settings;
  final int players;

  /// Who sits at the table (to pick where sound plays) and this player.
  final List<SeatView> seats;
  final PlayerId? you;
  final void Function(GameSettings) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = settings;
    final suggested = suggestedWerewolves(players.clamp(minPlayers, 99));
    final table = players.clamp(minPlayers, 99);
    final dropped = s.droppedFor(table);
    final children = [
      SettingsSection(l10n.settingsQuick),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, preset) in const [
              Preset.classic,
              Preset.whowolf,
            ].indexed) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: QuickPick(
                  title: l10n.preset(preset),
                  hint: preset == Preset.classic
                      ? l10n.quickClassicHint
                      : l10n.quickWhowolfHint,
                  selected: s.preset == preset,
                  onTap: () => onChanged(preset.settings.withTableOf(s)),
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),
      Center(
        child: s.preset == Preset.classic || s.preset == Preset.whowolf
            ? Body(l10n.settingsQuickHint, muted: true)
            : Stamp(l10n.settingsName(s), size: 16),
      ),
      SettingsSection(l10n.settingsRoles),
      BalancedGrid(
        children: [
          for (final role in specialRoles)
            RoleToggle(
              role: role,
              on: s.roles.contains(role),
              onTap: () => onChanged(
                s.copyWith(
                  roles: s.roles.contains(role)
                      ? ({...s.roles}..remove(role))
                      : {...s.roles, role},
                ),
              ),
            ),
        ],
      ),
      if (dropped.isNotEmpty) ...[
        const SizedBox(height: 10),
        Body(
          l10n.rolesFitted(
            table,
            [for (final r in dropped) l10n.role(r)].join(', '),
          ),
          muted: true,
        ),
      ],
      SettingsSection(l10n.settingsWolves),
      SettingsStepper(
        label: s.werewolves == null
            ? l10n.wolvesSuggested(suggested)
            : '${s.werewolves}',
        onLess: (s.werewolves ?? suggested) > 1
            ? () => onChanged(
                s.copyWith(werewolves: (s.werewolves ?? suggested) - 1),
              )
            : null,
        onMore: (s.werewolves ?? suggested) < maxWerewolves
            ? () => onChanged(
                s.copyWith(werewolves: (s.werewolves ?? suggested) + 1),
              )
            : null,
        onReset: s.werewolves == null
            ? null
            : () => onChanged(s.copyWith(suggestWerewolves: true)),
        resetLabel: l10n.wolvesSuggested(suggested),
      ),
      SettingsSection(l10n.settingsTimes),
      if (s.timedFor(table) != s)
        Align(
          child: TextButton.icon(
            onPressed: () => onChanged(s.timedFor(table)),
            icon: const Icon(Icons.auto_fix_high_rounded),
            label: Text(l10n.timesForTable(table)),
          ),
        ),
      TimeSlider(
        label: l10n.timeNight,
        value: s.nightTime,
        range: nightTimeRange,
        step: const Duration(seconds: 15),
        onChanged: (d) => onChanged(s.copyWith(nightTime: d)),
      ),
      TimeSlider(
        label: l10n.timeDay,
        value: s.dayTime,
        range: dayTimeRange,
        step: const Duration(minutes: 1),
        onChanged: (d) => onChanged(s.copyWith(dayTime: d)),
      ),
      TimeSlider(
        label: l10n.timeVote,
        value: s.voteTime,
        range: voteTimeRange,
        step: const Duration(seconds: 15),
        onChanged: (d) => onChanged(s.copyWith(voteTime: d)),
      ),
      SettingsSection(l10n.settingsNight),
      SettingsSwitch(
        label: l10n.settingsNightCalled,
        hint: s.nightMode == NightMode.called
            ? l10n.settingsNightCalledHint
            : l10n.settingsNightTogetherHint,
        value: s.nightMode == NightMode.called,
        onChanged: (v) => onChanged(
          s.copyWith(nightMode: v ? NightMode.called : NightMode.together),
        ),
      ),
      SettingsSection(l10n.settingsRules),
      SettingsSwitch(
        label: l10n.settingsRevealRoles,
        value: s.revealRoleOnDeath,
        onChanged: (v) => onChanged(s.copyWith(revealRoleOnDeath: v)),
      ),
      SettingsSwitch(
        label: l10n.settingsSeerRole,
        value: s.seerSeesRole,
        onChanged: (v) => onChanged(s.copyWith(seerSeesRole: v)),
      ),
      SettingsSwitch(
        label: l10n.settingsRunoff,
        value: s.tieRule == TieRule.runoff,
        onChanged: (v) => onChanged(
          s.copyWith(tieRule: v ? TieRule.runoff : TieRule.nobody),
        ),
      ),
      SettingsSwitch(
        label: l10n.settingsOpenVotes,
        hint: s.openVotes ? l10n.settingsOpenVotesHint : null,
        value: s.openVotes,
        onChanged: (v) => onChanged(s.copyWith(openVotes: v)),
      ),
      SettingsChoice<GhostSight>(
        label: l10n.settingsGhosts,
        segments: [
          ButtonSegment(value: GhostSight.off, label: Text(l10n.ghostsOff)),
          ButtonSegment(
            value: GhostSight.roles,
            label: Text(l10n.ghostsRoles),
          ),
          ButtonSegment(
            value: GhostSight.everything,
            label: Text(l10n.ghostsEverything),
          ),
        ],
        selected: s.ghosts,
        onChanged: (v) => onChanged(s.copyWith(ghosts: v)),
      ),
      if (s.ghosts != GhostSight.off)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Body(l10n.settingsGhostsHint, muted: true),
        ),
      SettingsSection(l10n.settingsExtras),
      // Both need the phones in hand at night: not in the called night.
      if (s.nightMode == NightMode.together) ...[
        SettingsSwitch(
          label: l10n.settingsSheep,
          hint: s.sheepCounting ? null : l10n.settingsSheepOff,
          value: s.sheepCounting,
          onChanged: (v) => onChanged(s.copyWith(sheepCounting: v)),
        ),
        SettingsSwitch(
          label: l10n.settingsDoorSigns,
          value: s.doorSigns,
          onChanged: (v) => onChanged(s.copyWith(doorSigns: v)),
        ),
      ],
      SettingsSwitch(
        label: l10n.settingsAtmosphere,
        value: s.atmosphere,
        onChanged: (v) => onChanged(s.copyWith(atmosphere: v)),
      ),
      SettingsSwitch(
        label: l10n.settingsWolfTrail,
        value: s.wolfTrail,
        onChanged: (v) => onChanged(s.copyWith(wolfTrail: v)),
      ),
      SettingsSection(l10n.settingsSound),
      SettingsChoice<NarratorMode>(
        label: l10n.settingsNarrator,
        segments: [
          ButtonSegment(value: NarratorMode.off, label: Text(l10n.narratorOff)),
          ButtonSegment(
            value: NarratorMode.moments,
            label: Text(l10n.narratorMoments),
          ),
          ButtonSegment(
            value: NarratorMode.always,
            label: Text(l10n.narratorAlways),
          ),
        ],
        selected: s.narratorMode,
        onChanged: (v) => onChanged(s.copyWith(narratorMode: v)),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Body(switch (s.narratorMode) {
          NarratorMode.off => l10n.narratorOffHint,
          NarratorMode.moments => l10n.narratorMomentsHint,
          NarratorMode.always => l10n.narratorAlwaysHint,
        }, muted: true),
      ),
      if (s.narratorVoice)
        SettingsChoice<NarratorLanguage>(
          label: l10n.settingsNarratorLanguage,
          segments: const [
            ButtonSegment(value: NarratorLanguage.de, label: Text('Deutsch')),
            ButtonSegment(value: NarratorLanguage.en, label: Text('English')),
          ],
          selected: s.narratorLanguage,
          onChanged: (v) => onChanged(s.copyWith(narratorLanguage: v)),
        ),
      _SoundPlaces(settings: s, seats: seats, you: you, onChanged: onChanged),
    ];
    // Each section on its own plaque, so it reads on any stage set; the
    // quick picks are plaques already. With room for it (tablet, desktop)
    // the sections stand in two columns.
    final groups = <List<Widget>>[];
    for (final child in children) {
      if (child is SettingsSection) groups.add([child]);
      if (child is! SettingsSection) groups.last.add(child);
    }
    Widget section(List<Widget> group, {bool plaque = true}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        group.first,
        if (plaque)
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: group.skip(1).toList(),
            ),
          )
        else
          ...group.skip(1),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) {
        final quick = section(groups.first, plaque: false);
        final rest = groups.skip(1).toList();
        if (box.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [quick, for (final g in rest) section(g)],
          );
        }
        // Balanced by order: roles, wolves and times on the left, the
        // night, the rules and the extras on the right.
        final half = (rest.length / 2).ceil();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            quick,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, part) in [
                  rest.take(half),
                  rest.skip(half),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [for (final g in part) section(g)],
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Where the narrator and the shared sounds play: every phone, only the
/// game leader's, a group, or one player's (e.g. with a speaker).
enum _Places { everyone, me, group, one }

class _SoundPlaces extends StatelessWidget {
  const _SoundPlaces({
    required this.settings,
    required this.seats,
    required this.you,
    required this.onChanged,
  });

  final GameSettings settings;
  final List<SeatView> seats;
  final PlayerId? you;
  final void Function(GameSettings) onChanged;

  _Places get _places {
    final chosen = settings.soundSeats;
    if (settings.soundMode == SoundMode.everyone || chosen.isEmpty) {
      return _Places.everyone;
    }
    if (chosen.length == 1) {
      return chosen.single == you ? _Places.me : _Places.one;
    }
    return _Places.group;
  }

  void _set(SoundMode mode, Set<PlayerId> seats) =>
      onChanged(settings.copyWith(soundMode: mode, soundSeats: seats));

  void _pick(_Places places) {
    final me = you;
    final ids = [for (final s in seats) s.id];
    switch (places) {
      case _Places.everyone:
        _set(SoundMode.everyone, const {});
      case _Places.me:
        if (me != null) _set(SoundMode.chosen, {me});
      case _Places.group:
        // Starts with everyone; the leader takes out who should be quiet.
        _set(SoundMode.chosen, ids.toSet());
      case _Places.one:
        final other = ids.where((id) => id != me).firstOrNull ?? me;
        if (other != null) _set(SoundMode.chosen, {other});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final places = _places;
    final chosen = settings.soundSeats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsChoice<_Places>(
          label: l10n.settingsSoundWhere,
          segments: [
            ButtonSegment(
              value: _Places.everyone,
              label: Text(l10n.soundEveryone),
            ),
            ButtonSegment(value: _Places.me, label: Text(l10n.soundMe)),
            ButtonSegment(value: _Places.group, label: Text(l10n.soundGroup)),
            ButtonSegment(value: _Places.one, label: Text(l10n.soundOne)),
          ],
          selected: places,
          onChanged: _pick,
        ),
        if (places == _Places.group || places == _Places.one)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final seat in seats)
                  FilterChip(
                    label: Text(seat.name),
                    selected: chosen.contains(seat.id),
                    showCheckmark: false,
                    avatar: Icon(
                      chosen.contains(seat.id)
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_outlined,
                      size: 18,
                    ),
                    onSelected: (on) {
                      if (places == _Places.one) {
                        _set(SoundMode.chosen, {seat.id});
                      } else if (on) {
                        _set(SoundMode.chosen, {...chosen, seat.id});
                      } else if (chosen.length > 1) {
                        _set(SoundMode.chosen, {...chosen}..remove(seat.id));
                      }
                    },
                  ),
              ],
            ),
          ),
        Body(
          places == _Places.everyone
              ? l10n.soundEveryoneHint
              : l10n.soundChosenHint,
          muted: true,
        ),
      ],
    );
  }
}
