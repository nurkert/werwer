import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private let powerSaver = PowerSaverStream()

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "WhowolfPower") {
      FlutterEventChannel(name: "whowolf/power", binaryMessenger: registrar.messenger())
        .setStreamHandler(powerSaver)
    }
  }
}

/// Tells Flutter whether the low power mode is on, now and on every change
/// (the stage calms down while it is).
final class PowerSaverStream: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    sink = events
    NotificationCenter.default.addObserver(
      self, selector: #selector(changed),
      name: .NSProcessInfoPowerStateDidChange, object: nil)
    events(ProcessInfo.processInfo.isLowPowerModeEnabled)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    NotificationCenter.default.removeObserver(self)
    sink = nil
    return nil
  }

  @objc private func changed() {
    let on = ProcessInfo.processInfo.isLowPowerModeEnabled
    DispatchQueue.main.async { [weak self] in self?.sink?(on) }
  }
}
