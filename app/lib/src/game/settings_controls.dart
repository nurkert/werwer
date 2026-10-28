import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/settings_sheet.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/theme.dart';

/// The controls the game settings are built from (task 004): sections,
/// toggles, steppers, sliders and choices in the stage's brass and
/// lantern look.
class SettingsSection extends StatelessWidget {
  const SettingsSection(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 28, 0, 10),
    child: Headline(title, size: 24),
  );
}

/// A quick pick: a whole way of playing in one tap, a playbill when chosen.
class QuickPick extends StatelessWidget {
  const QuickPick({
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
    super.key,
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
class RoleToggle extends StatelessWidget {
  const RoleToggle({
    required this.role,
    required this.on,
    required this.onTap,
    super.key,
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
            width: BalancedGrid.cell,
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

/// Cells in even rows: as many columns as fit, then spread so no row is
/// left with a straggler (four roles: one row of four, or two by two on a
/// phone; five: three and two).
class BalancedGrid extends StatelessWidget {
  const BalancedGrid({required this.children, super.key});

  final List<Widget> children;

  /// The width one cell needs.
  static const double cell = 78;
  static const double _gap = 12;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final n = children.length;
      if (n == 0) return const SizedBox.shrink();
      final fit = ((box.maxWidth + _gap) / (cell + _gap)).floor().clamp(1, n);
      final rows = (n / fit).ceil();
      final columns = (n / rows).ceil();
      return Column(
        children: [
          for (var r = 0; r < rows; r++) ...[
            if (r > 0) const SizedBox(height: 14),
            Row(
              children: [
                for (var c = 0; c < columns; c++)
                  Expanded(
                    child: r * columns + c < n
                        ? Center(child: children[r * columns + c])
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          ],
        ],
      );
    },
  );
}

class SettingsStepper extends StatelessWidget {
  const SettingsStepper({
    required this.label,
    required this.onLess,
    required this.onMore,
    required this.onReset,
    required this.resetLabel,
    super.key,
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
      BrassButton(icon: Icons.remove_rounded, onTap: onLess),
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
      BrassButton(icon: Icons.add_rounded, onTap: onMore),
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
class TimeSlider extends StatefulWidget {
  const TimeSlider({
    required this.label,
    required this.value,
    required this.range,
    required this.step,
    required this.onChanged,
    super.key,
  });

  final String label;
  final Duration value;
  final ({Duration min, Duration max}) range;
  final Duration step;
  final void Function(Duration) onChanged;

  @override
  State<TimeSlider> createState() => _TimeSliderState();
}

class _TimeSliderState extends State<TimeSlider> {
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

class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    super.key,
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
              LanternToggle(on: value),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The switch itself: a brass-edged slot, lit like a lantern when on.
class LanternToggle extends StatelessWidget {
  const LanternToggle({required this.on, super.key});

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
class BrassButton extends StatelessWidget {
  const BrassButton({required this.icon, required this.onTap, super.key});

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
class SettingsChoice<T> extends StatelessWidget {
  const SettingsChoice({
    required this.label,
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
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
