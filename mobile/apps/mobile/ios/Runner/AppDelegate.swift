import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let key = Self.dartDefine("GOOGLE_MAPS_KEY"), !key.isEmpty {
      GMSServices.provideAPIKey(key)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// A `--dart-define` value (from `--dart-define-from-file=secrets.json`),
  /// passed through Info.plist's DartDefines.
  static func dartDefine(_ name: String) -> String? {
    guard let all = Bundle.main.object(forInfoDictionaryKey: "DartDefines") as? String else { return nil }
    for item in all.split(separator: ",") {
      guard let data = Data(base64Encoded: String(item)),
            let pair = String(data: data, encoding: .utf8),
            pair.hasPrefix(name + "=") else { continue }
      return String(pair.dropFirst(name.count + 1))
    }
    return nil
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
