import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _channel = EventChannel('whowolf/power');

/// Whether the device's battery saver is on, now and whenever it changes:
/// Android's power saving mode, the low power mode on iPhone and Mac.
/// Elsewhere (browser, Windows, Linux) the system does not tell, and the
/// stream stays empty.
Stream<bool> powerSaverChanges() {
  if (kIsWeb) return const Stream.empty();
  switch (defaultTargetPlatform) {
    case TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.macOS:
      return _channel
          .receiveBroadcastStream()
          .map((on) => on == true)
          .handleError((Object _) {});
    case TargetPlatform.fuchsia ||
        TargetPlatform.linux ||
        TargetPlatform.windows:
      return const Stream.empty();
  }
}
