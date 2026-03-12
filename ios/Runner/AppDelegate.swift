import Flutter
import UIKit
import SafariServices

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var iyzicoChannel: FlutterMethodChannel?
  private weak var paymentSafari: SFSafariViewController?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as? FlutterViewController
    if let controller = controller {
      let channel = FlutterMethodChannel(name: "lingufranca/iyzico", binaryMessenger: controller.binaryMessenger)
      self.iyzicoChannel = channel
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "startPayment" else {
          result(FlutterMethodNotImplemented)
          return
        }

        guard
          let args = call.arguments as? [String: Any],
          let urlString = args["url"] as? String,
          let url = URL(string: urlString)
        else {
          result(FlutterError(code: "invalid_args", message: "Payment URL missing", details: nil))
          return
        }

        DispatchQueue.main.async {
          let config = SFSafariViewController.Configuration()
          config.entersReaderIfAvailable = false
          let safari = SFSafariViewController(url: url, configuration: config)
          safari.modalPresentationStyle = .pageSheet
          self?.paymentSafari = safari
          controller.present(safari, animated: true)
          result(true)
        }
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    // When the payment flow returns to the app via a custom URL scheme,
    // dismiss the in-app browser (SFSafariViewController) so the user sees the Flutter UI.
    if let safari = paymentSafari {
      safari.dismiss(animated: true)
      paymentSafari = nil
    } else if let controller = window?.rootViewController, controller.presentedViewController != nil {
      controller.dismiss(animated: true)
    }

    // Optional: also forward the deep link to Flutter (acts as a fallback).
    iyzicoChannel?.invokeMethod("deepLink", arguments: ["url": url.absoluteString])

    return super.application(app, open: url, options: options)
  }
}
