import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

@available(iOS 9.0, *)
override func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
    let controller = window.rootViewController as? FlutterBinaryMessenger

    let channel = FlutterMethodChannel(name: "plugins.flutter.io/quick_actions", binaryMessenger: controller!)
    channel.invokeMethod("launch", arguments: shortcutItem.type)
    }
}
