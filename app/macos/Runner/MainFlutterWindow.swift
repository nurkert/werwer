import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private let powerSaver = PowerSaverStream()

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    FlutterEventChannel(
      name: "whowolf/power", binaryMessenger: flutterViewController.engine.binaryMessenger
    ).setStreamHandler(powerSaver)

    super.awakeFromNib()
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
