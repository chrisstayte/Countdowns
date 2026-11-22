import UIKit
import UserNotifications
import Flutter

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
  }
}
