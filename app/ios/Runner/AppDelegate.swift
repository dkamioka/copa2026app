import Flutter
import UIKit
import WidgetKit

/// The App Group identifier shared with the CopaBracketWidget extension.
/// Must match the "App Groups" capability entitlement on BOTH this app
/// target and the widget extension target in Xcode — see
/// ios/CopaBracketWidget/WIDGET_SETUP.md.
let kCopaWidgetAppGroupId = "group.br.com.kamioka.worldcup2026"
private let kCopaWidgetChannelName = "copa2026/widget_bridge"
private let kCopaWidgetSnapshotKey = "bracket_snapshot"

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

    let channel = FlutterMethodChannel(
      name: kCopaWidgetChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "updateSnapshot":
        guard let json = call.arguments as? String else {
          result(FlutterError(code: "bad_args", message: "Expected a JSON string", details: nil))
          return
        }
        guard let defaults = UserDefaults(suiteName: kCopaWidgetAppGroupId) else {
          // Most likely cause: the App Group capability hasn't been added
          // to this target yet in Xcode — see WIDGET_SETUP.md. Surfacing
          // this as an error (rather than silently no-op'ing) makes that
          // misconfiguration visible instead of just leaving the widget
          // blank with no clue why.
          result(FlutterError(
            code: "no_app_group",
            message: "App Group '\(kCopaWidgetAppGroupId)' is not configured for this target.",
            details: nil
          ))
          return
        }
        defaults.set(json, forKey: kCopaWidgetSnapshotKey)
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadAllTimelines()
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
