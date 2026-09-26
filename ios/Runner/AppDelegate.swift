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

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SecureClipboardPlugin") {
      SecureClipboardPlugin.register(with: registrar)
    }
  }
}

/// Copies card numbers with a pasteboard expiry and keeps them off Universal Clipboard.
final class SecureClipboardPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "creditvance/secure", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(SecureClipboardPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "copySensitive":
      let args = call.arguments as? [String: Any]
      let text = args?["text"] as? String ?? ""
      let clearAfterMs = (args?["clearAfterMs"] as? NSNumber)?.doubleValue ?? 30000
      UIPasteboard.general.setItems(
        [[UIPasteboard.typeAutomatic: text]],
        options: [
          .localOnly: true,
          .expirationDate: Date().addingTimeInterval(clearAfterMs / 1000.0),
        ]
      )
      result(nil)
    case "clearClipboard":
      UIPasteboard.general.items = []
      result(nil)
    case "setSecureScreen":
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
