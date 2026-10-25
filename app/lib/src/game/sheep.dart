import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/theme.dart';

enum _Kind { white, lamb, black }

class _Sheep {
  _Sheep(this.kind, this.asset, this.born, this.lane);

  final _Kind kind;
  final String asset;
  final Duration born;
  final double lane;
  Duration? tappedAt;

  int get points => kind == _Kind.black ? -3 : 1;
}

/// Counting sheep, the decoy task: sheep hop over a fence; tapping a white
/// sheep (or lamb) gives a dream point, tapping a black one costs three.
/// Everyone gets it at night, so nobody stands out by tapping.
class SheepMeadow extends StatefulWidget {
  const SheepMeadow({
    required this.onPoints,
    super.key,
    this.flock,
    this.height = 220,
  });

  /// Called with the change in dream points (+1 or -3).
  final void Function(int delta) onPoints;

  /// How many sheep the host lets run tonight; endless without.
  final int? flock;
  final double height;

  @override
  State<SheepMeadow> createState() => _SheepMeadowState();
}

class _SheepMeadowState extends State<SheepMeadow>
    with SingleTickerProviderStateMixin {
  static const _run = Duration(milliseconds: 3600);
  static const _whites = [
    'assets/sheep/schaf_1.webp',
    'assets/sheep/schaf_2.webp',
    'assets/sheep/schaf_3.webp',
    'assets/sheep/schaf_4.webp',
  ];

  final _random = Random();
  final _sheep = <_Sheep>[];
  late final Ticker _ticker;
  Duration _now = Duration.zero;
  Duration _nextSpawn = Duration.zero;
  int _score = 0;
  int _spawned = 0;

  /// Pause between sheep: the flock spreads over about half a minute.
  Duration get _gap {
    final flock = widget.flock;
    final base = flock == null ? 1000 : (30000 / flock).clamp(600, 6000);
    return Duration(
      milliseconds: (base * (0.6 + _random.nextDouble() * 0.8)).round(),
    );
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    unawaited(_ticker.start());
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    _now = elapsed;
    final flock = widget.flock;
    final more = flock == null || _spawned < flock;
    if (more && elapsed >= _nextSpawn) {
      _spawned++;
      final roll = _random.nextDouble();
      final kind = roll < 0.22
          ? _Kind.black
          : roll < 0.32
          ? _Kind.lamb
          : _Kind.white;
      final asset = switch (kind) {
        _Kind.black => 'assets/sheep/schwarzes_schaf.webp',
        _Kind.lamb => 'assets/sheep/lamm.webp',
        _Kind.white => _whites[_random.nextInt(_whites.length)],
      };
      _sheep.add(_Sheep(kind, asset, elapsed, _random.nextDouble()));
      _nextSpawn = elapsed + _gap;
    }
    _sheep.removeWhere(
      (s) =>
          elapsed - s.born > _run ||
          (s.tappedAt != null &&
              elapsed - s.tappedAt! > const Duration(milliseconds: 600)),
    );
    setState(() {});
  }

  void _tap(_Sheep sheep) {
    if (sheep.tappedAt != null) return;
    sheep.tappedAt = _now;
    _score += sheep.points;
    widget.onPoints(sheep.points);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final h = widget.height;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: h,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final size = h * 0.34;
            return Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF1A2347), Color(0xFF2B3A6E)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: h * 0.45,
                  child: Image.asset(
                    'assets/sheep/wiese.webp',
                    repeat: ImageRepeat.repeatX,
                    fit: BoxFit.fitHeight,
                    alignment: Alignment.bottomLeft,
                  ),
                ),
                Positioned(
                  left: w / 2 - h * 0.17,
                  bottom: h * 0.12,
                  height: h * 0.3,
                  child: Image.asset('assets/sheep/zaun.webp'),
                ),
                for (final s in _sheep) _sprite(s, w, h, size),
                Positioned(
                  left: 12,
                  top: 10,
                  child: Text(
                    l10n.dreamPoints(_score),
                    style: const TextStyle(
                      color: Palette.moon100,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sprite(_Sheep s, double w, double h, double size) {
    final t = ((_now - s.born).inMilliseconds / _run.inMilliseconds).clamp(
      0.0,
      1.0,
    );
    final x = -size + t * (w + size);
    // Small hops all the way, a big jump over the fence in the middle.
    final fence = (1 - ((t - 0.5).abs() / 0.12)).clamp(0.0, 1.0);
    final hop = sin(t * pi * 10).abs() * h * 0.04 + fence * h * 0.28;
    final bottom = h * (0.1 + s.lane * 0.12) + hop;
    final tapped = s.tappedAt != null;
    final fade = tapped
        ? 1 - ((_now - s.tappedAt!).inMilliseconds / 600).clamp(0.0, 1.0)
        : 1.0;
    return Positioned(
      left: x,
      bottom: bottom + (tapped ? (1 - fade) * 30 : 0),
      width: size * (s.kind == _Kind.lamb ? 0.8 : 1),
      // A fixed box, so the tap target exists before the image has loaded.
      height: size * (s.kind == _Kind.lamb ? 0.7 : 0.85),
      child: Opacity(
        opacity: fade,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _tap(s),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned.fill(
                child: Image.asset(s.asset, gaplessPlayback: true),
              ),
              if (tapped)
                Positioned(
                  top: -18,
                  child: Text(
                    s.points > 0 ? '+${s.points}' : '${s.points}',
                    style: TextStyle(
                      fontFamily: displayFont,
                      fontSize: 20,
                      color: s.points > 0
                          ? Palette.lantern400
                          : Palette.curtain400,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
