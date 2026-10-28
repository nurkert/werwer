import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/theme.dart';

/// Whether this platform has a camera scanner.
bool get canScan => Platform.isIOS || Platform.isAndroid || Platform.isMacOS;

/// Scans a room QR code; pops with the parsed [JoinLink]. Anything that is not
/// a valid Whowolf link is ignored with a hint, never opened.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _camera = MobileScannerController();
  bool _done = false;
  bool _invalid = false;

  @override
  void dispose() {
    unawaited(_camera.dispose());
    super.dispose();
  }

  void _detect(BarcodeCapture capture) {
    if (_done) return;
    for (final code in capture.barcodes) {
      final raw = code.rawValue;
      if (raw == null) continue;
      final link = JoinLink.tryParse(raw);
      if (link != null) {
        _done = true;
        Navigator.pop(context, link);
        return;
      }
      if (!_invalid) setState(() => _invalid = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Palette.stageInk,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Palette.moon100,
        actions: [
          IconButton(
            tooltip: l10n.scanLight,
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: () => unawaited(_camera.toggleTorch()),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, box) {
          final side = min(box.maxWidth, box.maxHeight) * 0.66;
          final window = Rect.fromCenter(
            center: box.biggest.center(Offset.zero),
            width: side,
            height: side,
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(controller: _camera, onDetect: _detect),
              // The night around the stage opening, the brass frame and its
              // lantern corners: the code goes in the light.
              IgnorePointer(
                child: CustomPaint(painter: _Frame(window)),
              ),
              Positioned(
                left: 28,
                right: 28,
                bottom: box.maxHeight - window.top + 24,
                child: Column(
                  children: [
                    Text(
                      l10n.scanTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: displayFont,
                        fontSize: 28,
                        color: Palette.stageMoonlight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.scanHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Palette.moon200),
                    ),
                  ],
                ),
              ),
              if (_invalid)
                Positioned(
                  left: 28,
                  right: 28,
                  top: window.bottom + 28,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Palette.paper,
                        borderRadius: BorderRadius.circular(Radii.s),
                        border: Border.all(color: Palette.stageBrass, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Text(
                          l10n.scanInvalid,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Palette.ink),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Frame extends CustomPainter {
  _Frame(this.window);

  final Rect window;

  @override
  void paint(Canvas canvas, Size size) {
    final opening = RRect.fromRectAndRadius(window, const Radius.circular(18));
    canvas
      ..drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Offset.zero & size),
          Path()..addRRect(opening),
        ),
        Paint()..color = Palette.stageInk.withValues(alpha: 0.74),
      )
      ..drawRRect(
        opening.inflate(3),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = Palette.stageBrass,
      )
      ..drawRRect(
        opening.inflate(7),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Palette.stageBrassLight.withValues(alpha: 0.6),
      );
    final corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = Palette.stageLantern;
    const arm = 28.0;
    final r = window.inflate(3);
    for (final (point, dx, dy) in [
      (r.topLeft, 1.0, 1.0),
      (r.topRight, -1.0, 1.0),
      (r.bottomLeft, 1.0, -1.0),
      (r.bottomRight, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(point, point + Offset(arm * dx, 0), corner)
        ..drawLine(point, point + Offset(0, arm * dy), corner);
    }
  }

  @override
  bool shouldRepaint(_Frame old) => old.window != window;
}
