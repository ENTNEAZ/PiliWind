import UIKit
import Flutter

@UIApplicationMain
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
    GeneratedPluginRegistrant.register(with: self)
    NSLog("[PW] didFinishLaunching begin")

    // 安全获取 FlutterViewController（避免 as! 直接崩）
    let root = window?.rootViewController
    let flutterVC =
      root as? FlutterViewController ??
      (root as? UINavigationController)?.topViewController as? FlutterViewController ??
      root?.children.first as? FlutterViewController

    if flutterVC == nil {
      NSLog("[PW] FlutterViewController NOT found in root hierarchy")
    } else {
      NSLog("[PW] FlutterViewController found; setting up MethodChannel")
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
      NSLog("[PW] MethodChannel call: \(call.method)")

      switch call.method {
      case "lockLandscape":
        AppDelegate.orientationLock = .landscape
        if #available(iOS 16.0, *) {
          if let scene = self.window?.windowScene {
            scene.requestGeometryUpdate(
              .iOS(interfaceOrientations: AppDelegate.orientationLock)
            ) { error in
              NSLog("[PW] requestGeometryUpdate error: \(error.localizedDescription)")
            }
          }
        }
        UIViewController.attemptRotationToDeviceOrientation()
        result(nil)

      case "unlockPortraitFirst":
        AppDelegate.orientationLock = .allButUpsideDown
        if #available(iOS 16.0, *) {
          if let scene = self.window?.windowScene {
            scene.requestGeometryUpdate(
              .iOS(interfaceOrientations: AppDelegate.orientationLock)
            ) { error in
              NSLog("[PW] requestGeometryUpdate error: \(error.localizedDescription)")
            }
          }
        }
        UIViewController.attemptRotationToDeviceOrientation()
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    NSLog("[PW] didFinishLaunching end")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
