import UIKit
import UserNotifications
import Flutter
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    UNUserNotificationCenter.current().delegate = self

    // when user reinstalls application old notifications will be deleted
    if !UserDefaults.standard.bool(forKey: "Notification") {
      UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
      UserDefaults.standard.set(true, forKey: "Notification")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CountdownsWidgets") {
      WidgetBridge.register(messenger: registrar.messenger())
    }
  }
}

/// Lets the Flutter app write the widget snapshot into the shared App Group
/// container and ask WidgetKit to reload. Our own code, no plugin.
enum WidgetBridge {
  static let appGroup = "group.com.chrisstayte.countdowns"
  private static var channel: FlutterMethodChannel?

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "countdowns/widgets", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "containerPath":
        let url = FileManager.default.containerURL(
          forSecurityApplicationGroupIdentifier: appGroup)
        result(url?.path)
      case "reload":
        WidgetCenter.shared.reloadAllTimelines()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }
}
