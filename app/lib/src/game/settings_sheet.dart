import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/theme.dart';

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

/// Opens the host's settings for the next game. Every change goes to the
/// host at once (it checks and broadcasts them), so the sheet always shows
/// what the table will play.
Future<void> showSettingsSheet(BuildContext context, GameSession session) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        builder: (context, scroll) => ListenableBuilder(
          listenable: session,
          builder: (context, _) {
            final view = session.view;
            if (view == null) return const SizedBox.shrink();
            return _SettingsBody(
              settings: view.settings,
              players: view.seats.length,
              scroll: scroll,
              onChanged: (settings) => session.send(SettingsIntent(settings)),
            );
          },
        ),
      ),
    );

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.settings,
    required this.players,
    required this.scroll,
    required this.onChanged,
  });

  final GameSettings settings;
  final int players;
  final ScrollController scroll;
  final void Function(GameSettings) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = settings;
    final suggested = suggestedWerewolves(players.clamp(minPlayers, 99));
    final fits = s.rolesFor(players.clamp(minPlayers, 99)) != null;
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        Headline(l10n.settingsTitle),
        const SizedBox(height: 16),
        for (final preset in Preset.values) ...[
          _PresetCard(
            preset: preset,
            selected: s.preset == preset,
            onTap: () => onChanged(
              preset.settings.copyWith(narratorLanguage: s.narratorLanguage),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (s.preset == null)
          Center(child: Stamp(l10n.settingsName(s), size: 16)),
        _Section(l10n.settingsRoles),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final role in specialRoles)
              _RoleToggle(
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
        if (!fits) ...[
          const SizedBox(height: 10),
          Body(l10n.tooManyRoles(players), muted: true),
        ],
        _Section(l10n.settingsWolves),
        _Stepper(
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
        _Section(l10n.settingsTimes),
        _TimeSlider(
          label: l10n.timeNight,
          value: s.nightTime,
          range: nightTimeRange,
          step: const Duration(seconds: 15),
          onChanged: (d) => onChanged(s.copyWith(nightTime: d)),
        ),
        _TimeSlider(
          label: l10n.timeDay,
          value: s.dayTime,
          range: dayTimeRange,
          step: const Duration(minutes: 1),
          onChanged: (d) => onChanged(s.copyWith(dayTime: d)),
        ),
        _TimeSlider(
          label: l10n.timeVote,
          value: s.voteTime,
          range: voteTimeRange,
          step: const Duration(seconds: 15),
          onChanged: (d) => onChanged(s.copyWith(voteTime: d)),
        ),
        _Section(l10n.settingsNight),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.settingsNarratorLanguage,
                style: const TextStyle(color: Palette.moon100),
              ),
            ),
            SegmentedButton<NarratorLanguage>(
              segments: const [
                ButtonSegment(value: NarratorLanguage.de, label: Text('DE')),
                ButtonSegment(value: NarratorLanguage.en, label: Text('EN')),
              ],
              selected: {s.narratorLanguage},
              onSelectionChanged: (v) =>
                  onChanged(s.copyWith(narratorLanguage: v.first)),
            ),
          ],
        ),
        _Switch(
          label: l10n.settingsNightCalled,
          hint: s.nightMode == NightMode.called
              ? l10n.settingsNightCalledHint
              : l10n.settingsNightTogetherHint,
          value: s.nightMode == NightMode.called,
          onChanged: (v) => onChanged(
            s.copyWith(nightMode: v ? NightMode.called : NightMode.together),
          ),
        ),
        _Section(l10n.settingsRules),
        _Switch(
          label: l10n.settingsRevealRoles,
          value: s.revealRoleOnDeath,
          onChanged: (v) => onChanged(s.copyWith(revealRoleOnDeath: v)),
        ),
        _Switch(
          label: l10n.settingsSeerRole,
          value: s.seerSeesRole,
          onChanged: (v) => onChanged(s.copyWith(seerSeesRole: v)),
        ),
        _Section(l10n.settingsExtras),
        // Both need the phones in hand at night: not in the called night.
        if (s.nightMode == NightMode.together) ...[
          _Switch(
            label: l10n.settingsSheep,
            hint: s.sheepCounting ? null : l10n.settingsSheepOff,
            value: s.sheepCounting,
            onChanged: (v) => onChanged(s.copyWith(sheepCounting: v)),
          ),
          _Switch(
            label: l10n.settingsDoorSigns,
            value: s.doorSigns,
            onChanged: (v) => onChanged(s.copyWith(doorSigns: v)),
          ),
        ],
        _Switch(
          label: l10n.settingsAtmosphere,
          value: s.atmosphere,
          onChanged: (v) => onChanged(s.copyWith(atmosphere: v)),
        ),
        _Switch(
          label: l10n.settingsWolfTrail,
          value: s.wolfTrail,
          onChanged: (v) => onChanged(s.copyWith(wolfTrail: v)),
        ),
        _Switch(
          label: l10n.settingsPersonas,
          value: s.personaChoice,
          onChanged: (v) => onChanged(s.copyWith(personaChoice: v)),
        ),
        _Switch(
          label: l10n.settingsVoice,
          value: s.narratorVoice,
          onChanged: (v) => onChanged(s.copyWith(narratorVoice: v)),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 28, 0, 10),
    child: Headline(title, size: 24),
  );
}

/// One preset as a playbill card: name, a line about it, a stamp if chosen.
class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final Preset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Panel(
          paper: selected,
          highlight: selected,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.preset(preset),
                      style: TextStyle(
                        fontFamily: displayFont,
                        fontSize: 24,
                        color: selected ? Palette.ink : Palette.moon100,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.presetText(preset),
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.4,
                        color: selected ? Palette.inkSoft : Palette.moon200,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 10),
                const Icon(
                  Icons.check_circle_rounded,
                  color: Palette.forest700,
                  size: 28,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A special role: its figure, its name, on or off.
class _RoleToggle extends StatelessWidget {
  const _RoleToggle({
    required this.role,
    required this.on,
    required this.onTap,
  });

  final Role role;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      toggled: on,
      label: l10n.role(role),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: on ? 1 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: SizedBox(
            width: 78,
            child: Column(
              children: [
                RoleFigure(role: role, height: 92),
                const SizedBox(height: 6),
                Text(
                  l10n.role(role),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Palette.moon100,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  on ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: on ? Palette.lantern400 : Palette.night500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.onLess,
    required this.onMore,
    required this.onReset,
    required this.resetLabel,
  });

  final String label;
  final VoidCallback? onLess;
  final VoidCallback? onMore;
  final VoidCallback? onReset;
  final String resetLabel;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton.outlined(
        onPressed: onLess,
        icon: const Icon(Icons.remove_rounded),
      ),
      SizedBox(
        width: 150,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Palette.moon100,
          ),
        ),
      ),
      IconButton.outlined(
        onPressed: onMore,
        icon: const Icon(Icons.add_rounded),
      ),
      if (onReset != null)
        IconButton(
          onPressed: onReset,
          icon: const Icon(Icons.auto_fix_high_rounded),
          color: Palette.lantern300,
          tooltip: resetLabel,
        ),
    ],
  );
}

/// A phase time. Dragging only moves the label; the value goes to the host
/// when the finger lifts (one message, not one per pixel: the host limits
/// how many messages a player may send).
class _TimeSlider extends StatefulWidget {
  const _TimeSlider({
    required this.label,
    required this.value,
    required this.range,
    required this.step,
    required this.onChanged,
  });

  final String label;
  final Duration value;
  final ({Duration min, Duration max}) range;
  final Duration step;
  final void Function(Duration) onChanged;

  @override
  State<_TimeSlider> createState() => _TimeSliderState();
}

class _TimeSliderState extends State<_TimeSlider> {
  Duration? _dragging;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = _dragging ?? widget.value;
    final min = widget.range.min.inSeconds.toDouble();
    final max = widget.range.max.inSeconds.toDouble();
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            widget.label,
            style: const TextStyle(color: Palette.moon200),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.inSeconds.toDouble().clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) / widget.step.inSeconds).round(),
            label: l10n.duration(value),
            onChanged: (v) =>
                setState(() => _dragging = Duration(seconds: v.round())),
            onChangeEnd: (v) {
              setState(() => _dragging = null);
              widget.onChanged(Duration(seconds: v.round()));
            },
          ),
        ),
        SizedBox(
          width: 64,
          child: Text(
            l10n.duration(value),
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Palette.moon100,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    value: value,
    onChanged: onChanged,
    activeThumbColor: Palette.lantern400,
    title: Text(label, style: const TextStyle(color: Palette.moon100)),
    subtitle: hint == null
        ? null
        : Text(hint!, style: const TextStyle(color: Palette.moon200)),
  );
}
