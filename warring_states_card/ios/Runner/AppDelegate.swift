import Flutter
import UIKit
import StoreKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if DEBUG
    startStoreKitTestSession()
    #endif
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// 加载本地 Configuration.storekit，让模拟器在 DEBUG 下能返回测试商品，
  /// 无需连接真实 App Store Connect。真机/Release 不受影响。
  #if DEBUG
  private func startStoreKitTestSession() {
    let bundle = Bundle(for: AppDelegate.self)
    guard let url = bundle.url(forResource: "Configuration", withExtension: "storekit") else {
      debugPrint("⚠️ 未找到 Configuration.storekit，IAP 将连接真实 App Store")
      return
    }
    do {
      let session = try SKTestSession(contentsOf: url)
      session.resetToDefaultState()
      session.disableDialogs = true
      session.clearTransactions()
      debugPrint("🔵 StoreKit 测试会话已加载: \(url.lastPathComponent)")
    } catch {
      debugPrint("🔴 加载 StoreKit 测试会话失败: \(error.localizedDescription)")
    }
  }
  #endif

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
