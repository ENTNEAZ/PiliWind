import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {

  static var orientationLock: UIInterfaceOrientationMask = .allButUpsideDown

  override func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    return AppDelegate.orientationLock
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    NSLog("[PW] didFinishLaunching begin")  // ← 路标1

    // ✅ 安全拿 FlutterViewController（避免 as! 直接崩）
    let root = window?.rootViewController
    let flutterVC =
      root as? FlutterViewController ??
      (root as? UINavigationController)?.topViewController as? FlutterViewController ??
      root?.children.first as? FlutterViewController

    if flutterVC == nil {
      NSLog("[PW] FlutterViewController not found in root VC hierarchy") // ← 路标2（若找不到会打印）
    } else {
      NSLog("[PW] FlutterViewController found, setting up method channel") // ← 路标2
    }

    guard let controller = flutterVC else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    let channel = FlutterMethodChannel(
      name: "app.orientation/lock",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      NSLog("[PW] MethodChannel call: \(call.method)") // ← 路标3：收到 Dart 调用
      switch call.method {
      case "lockLandscape":
        AppDelegate.orientationLock = .landscape
        if #available(iOS 16.0, *) {
          self.window?.windowScene?.requestGeometryUpdate(
            .iOS(interfaceOrientations: AppDelegate.orientationLock)
          ) { err in
            if let err = err { NSLog("[PW] requestGeometryUpdate error: \(err)") }
          }
        }
        UIViewController.attemptRotationToDeviceOrientation()
        result(nil)

      case "unlockPortraitFirst":
        AppDelegate.orientationLock = .allButUpsideDown
        if #available(iOS 16.0, *) {
          self.window?.windowScene?.requestGeometryUpdate(
            .iOS(interfaceOrientations: AppDelegate.orientationLock)
          ) { err in
            if let err = err { NSLog("[PW] requestGeometryUpdate error: \(err)") }
          }
        }
        UIViewController.attemptRotationToDeviceOrientation()
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    NSLog("[PW] didFinishLaunching end") // ← 路标4

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
