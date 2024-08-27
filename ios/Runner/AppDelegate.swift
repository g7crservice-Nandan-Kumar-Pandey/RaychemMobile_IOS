import Flutter
import UIKit
import flutter_downloader // Import the necessary plugin

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Ensure plugin is initialized
    FlutterDownloaderPlugin.setPluginRegistrantCallback { registry in
        if let registrar = registry.registrar(forPlugin: "flutter_downloader") {
            FlutterDownloaderPlugin.register(with: registrar)
        }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
