import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  // 当前 App 允许的方向集合；默认维持你项目的“竖屏优先”
  static var orientationLock: UIInterfaceOrientationMask = .allButUpsideDown

  // 系统每次需要布局或解锁时都会问这里：你现在允许哪些方向？
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

    let flutterVC = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "app.orientation/lock",
      binaryMessenger: flutterVC.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {

      case "lockLandscape":
        // 只允许横向（左右都行）；解锁后系统直接保持横向，不会“先竖一帧”
        AppDelegate.orientationLock = .landscape
        if #available(iOS 16.0, *) {
          self.window?.windowScene?.requestGeometryUpdate(
            .iOS(interfaceOrientations: AppDelegate.orientationLock)
          ) { _ in }
        }
        UIViewController.attemptRotationToDeviceOrientation()
        result(nil)

      case "unlockPortraitFirst":
        // 恢复到你的全局设置（竖屏优先，避免返回时卡在横屏）
        AppDelegate.orientationLock = .allButUpsideDown
        if #available(iOS 16.0, *) {
          self.window?.windowScene?.requestGeometryUpdate(
            .iOS(interfaceOrientations: AppDelegate.orientationLock)
          ) { _ in }
        }
        UIViewController.attemptRotationToDeviceOrientation()
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
