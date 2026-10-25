import 'dart:io';

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
  bool _done = false;
  bool _invalid = false;

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
      appBar: AppBar(
        backgroundColor: Palette.night900,
        foregroundColor: Palette.moon100,
        title: Text(l10n.scanTitle),
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _detect),
          if (_invalid)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Palette.night900,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      l10n.scanInvalid,
                      style: const TextStyle(color: Palette.moon100),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
