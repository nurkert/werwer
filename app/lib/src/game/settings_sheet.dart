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
  });

  final GameSettings settings;
  final int players;
  final void Function(GameSettings) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = settings;
    final suggested = suggestedWerewolves(players.clamp(minPlayers, 99));
    final fits = s.rolesFor(players.clamp(minPlayers, 99)) != null;
    final children = [
      _Section(l10n.settingsQuick),
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
                child: _QuickPick(
                  title: l10n.preset(preset),
                  hint: preset == Preset.classic
                      ? l10n.quickClassicHint
                      : l10n.quickWhowolfHint,
                  selected: s.preset == preset,
                  onTap: () => onChanged(
                    preset.settings.copyWith(
                      narratorLanguage: s.narratorLanguage,
                    ),
                  ),
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
      _Choice<NarratorLanguage>(
        label: l10n.settingsNarratorLanguage,
        segments: const [
          ButtonSegment(value: NarratorLanguage.de, label: Text('Deutsch')),
          ButtonSegment(value: NarratorLanguage.en, label: Text('English')),
        ],
        selected: s.narratorLanguage,
        onChanged: (v) => onChanged(s.copyWith(narratorLanguage: v)),
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
      _Switch(
        label: l10n.settingsRunoff,
        value: s.tieRule == TieRule.runoff,
        onChanged: (v) => onChanged(
          s.copyWith(tieRule: v ? TieRule.runoff : TieRule.nobody),
        ),
      ),
      _Choice<GhostSight>(
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
        label: l10n.settingsVoice,
        value: s.narratorVoice,
        onChanged: (v) => onChanged(s.copyWith(narratorVoice: v)),
      ),
    ];
    // Each section on its own plaque, so it reads on any stage set; the
    // quick picks are plaques already. With room for it (tablet, desktop)
    // the sections stand in two columns.
    final groups = <List<Widget>>[];
    for (final child in children) {
      if (child is _Section) groups.add([child]);
      if (child is! _Section) groups.last.add(child);
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

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 28, 0, 10),
    child: Headline(title, size: 24),
  );
}

/// A quick pick: a whole way of playing in one tap, a playbill when chosen.
class _QuickPick extends StatelessWidget {
  const _QuickPick({
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Panel(
        paper: selected,
        highlight: selected,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: displayFont,
                      fontSize: 22,
                      color: selected ? Palette.ink : Palette.moon100,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Palette.forest700,
                    size: 22,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.35,
                color: selected ? Palette.inkSoft : Palette.moon200,
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
      _BrassButton(icon: Icons.remove_rounded, onTap: onLess),
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
      _BrassButton(icon: Icons.add_rounded, onTap: onMore),
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
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      toggled: value,
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.s),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Palette.moon100,
                      ),
                    ),
                    if (hint != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        hint!,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.35,
                          color: Palette.moon200,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _LanternToggle(on: value),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The switch itself: a brass-edged slot, lit like a lantern when on.
class _LanternToggle extends StatelessWidget {
  const _LanternToggle({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 200);
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      width: 54,
      height: 32,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: on ? Palette.stageLanternTop : Palette.stageBrass,
          width: 1.5,
        ),
        color: on
            ? Palette.stageLantern
            : Palette.night950.withValues(
                alpha: 0.7,
              ),
        boxShadow: [
          if (on)
            BoxShadow(
              color: Palette.stageLantern.withValues(alpha: 0.45),
              blurRadius: 12,
            ),
        ],
      ),
      child: AnimatedAlign(
        duration: duration,
        curve: Curves.easeOut,
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 23,
          height: 23,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? Palette.stageIvory : Palette.stageBrassLight,
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round brass button (more, fewer).
class _BrassButton extends StatelessWidget {
  const _BrassButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onTap == null ? 0.4 : 1,
    child: Material(
      color: Palette.stagePlaque,
      shape: const CircleBorder(
        side: BorderSide(color: Palette.stageBrass, width: 1.5),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: Palette.stageIvory),
        ),
      ),
    ),
  );
}

/// One of a few choices, its label above and the choices across the full
/// width (they fit on a phone, they never squeeze the label).
class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<ButtonSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Palette.moon100),
        ),
        const SizedBox(height: 8),
        SegmentedButton<T>(
          segments: segments,
          selected: {selected},
          showSelectedIcon: false,
          onSelectionChanged: (v) => onChanged(v.first),
        ),
      ],
    ),
  );
}
