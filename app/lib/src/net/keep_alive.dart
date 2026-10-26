import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Keeps the host's socket alive while the app is in the background.
///
/// On Android this runs a foreground service with a small, silent
/// notification while a room is open; without it Android may kill the
/// process (and with it the room) a few minutes after the screen turns off.
/// Other platforms have nothing comparable, so this is a no-op there.
abstract final class KeepAlive {
  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Starts the service; returns whether it runs. Never throws.
  static Future<bool> start({
    required String title,
    required String text,
  }) async {
    if (!_supported) return false;
    try {
      // Without the permission the service still runs, Android only hides
      // the notification; asked once, never again after a "no".
      final permission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (permission == NotificationPermission.denied) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'room',
          channelName: 'Whowolf',
          // Low importance and silent by default: it only says the room
          // is open.
          onlyAlertOnce: true,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          // No background work: the service only keeps the process alive.
          eventAction: ForegroundTaskEventAction.nothing(),
          allowWifiLock: true,
          // A room cannot come back by restarting the service alone.
          allowAutoRestart: false,
          stopWithTask: true,
        ),
      );
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
        );
        return true;
      }
      final result = await FlutterForegroundTask.startService(
        serviceTypes: [ForegroundServiceTypes.connectedDevice],
        notificationTitle: title,
        notificationText: text,
      );
      return result is ServiceRequestSuccess;
    } on Object {
      return false;
    }
  }

  /// Stops the service, if it runs. Never throws.
  static Future<void> stop() async {
    if (!_supported) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } on Object {
      // Already gone.
    }
  }
}
