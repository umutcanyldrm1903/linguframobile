import AVFoundation
import Flutter
import MobileRTC
import SafariServices
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, MobileRTCAuthDelegate {
  private var iyzicoChannel: FlutterMethodChannel?
  private var zoomChannel: FlutterMethodChannel?
  private weak var paymentSafari: SFSafariViewController?

  private var zoomInitInProgress = false
  private var pendingZoomInitResults: [FlutterResult] = []

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = currentFlutterController() {
      let paymentChannel = FlutterMethodChannel(
        name: "lingufranca/iyzico",
        binaryMessenger: controller.binaryMessenger
      )
      iyzicoChannel = paymentChannel
      paymentChannel.setMethodCallHandler { [weak self] call, result in
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

      let zoomMethodChannel = FlutterMethodChannel(
        name: "lingufranca/zoom_meeting",
        binaryMessenger: controller.binaryMessenger
      )
      zoomChannel = zoomMethodChannel
      zoomMethodChannel.setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result(
            FlutterError(
              code: "sdk_not_available",
              message: "Zoom SDK is unavailable",
              details: nil
            )
          )
          return
        }

        switch call.method {
        case "initialize":
          let args = call.arguments as? [String: Any]
          let jwtToken = (args?["jwtToken"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
          self.initializeZoom(jwtToken: jwtToken, result: result)
        case "joinMeeting":
          let args = call.arguments as? [String: Any]
          let meetingId = (args?["meetingId"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
          let password = (args?["password"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
          let displayName = (args?["displayName"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
          self.joinMeeting(
            meetingId: meetingId,
            password: password,
            displayName: displayName,
            result: result
          )
        default:
          result(FlutterMethodNotImplemented)
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
    if let safari = paymentSafari {
      safari.dismiss(animated: true)
      paymentSafari = nil
    } else if let controller = window?.rootViewController, controller.presentedViewController != nil {
      controller.dismiss(animated: true)
    }

    iyzicoChannel?.invokeMethod("deepLink", arguments: ["url": url.absoluteString])

    return super.application(app, open: url, options: options)
  }

  func onMobileRTCAuthReturn(_ returnValue: MobileRTCAuthError) {
    zoomInitInProgress = false
    let results = pendingZoomInitResults
    pendingZoomInitResults.removeAll()

    if returnValue == .success {
      for result in results {
        result(["status": "initialized"])
      }
      return
    }

    for result in results {
      result(
        FlutterError(
          code: "zoom_auth_failed",
          message: "Zoom SDK auth failed: \(returnValue.rawValue)",
          details: nil
        )
      )
    }
  }

  private func initializeZoom(jwtToken: String, result: @escaping FlutterResult) {
    guard !jwtToken.isEmpty else {
      result(FlutterError(code: "missing_jwt", message: "Zoom SDK JWT token is missing", details: nil))
      return
    }

    if isZoomAuthorized() {
      result(["status": "initialized"])
      return
    }

    pendingZoomInitResults.append(result)
    if zoomInitInProgress {
      return
    }
    zoomInitInProgress = true

    let sdk = MobileRTC.shared()

    let context = MobileRTCSDKInitContext()
    context.domain = "zoom.us"
    context.enableLog = true

    if !sdk.initialize(context) {
      flushZoomInitFailure(code: "zoom_init_failed", message: "Zoom SDK could not be initialized")
      return
    }

    if let controller = presentableRootController() {
      sdk.setMobileRTCRootController(controller)
    }

    guard let authService = sdk.getAuthService() else {
      flushZoomInitFailure(code: "zoom_init_failed", message: "Zoom auth service is unavailable")
      return
    }

    authService.delegate = self
    authService.jwtToken = jwtToken
    authService.sdkAuth()
  }

  private func joinMeeting(
    meetingId: String,
    password: String,
    displayName: String,
    result: @escaping FlutterResult
  ) {
    guard !meetingId.isEmpty else {
      result(FlutterError(code: "missing_meeting_id", message: "Meeting ID is missing", details: nil))
      return
    }

    guard isZoomAuthorized() else {
      result(
        FlutterError(
          code: "zoom_not_initialized",
          message: "Zoom SDK is not initialized",
          details: nil
        )
      )
      return
    }

    ensureZoomPermissions { [weak self] granted in
      guard let self else { return }
      guard granted else {
        result(
          FlutterError(
            code: "permission_denied",
            message: "Camera and microphone permissions are required to join the lesson",
            details: nil
          )
        )
        return
      }

      let sdk = MobileRTC.shared()

      if let controller = self.presentableRootController() {
        sdk.setMobileRTCRootController(controller)
      }

      guard let meetingService = sdk.getMeetingService() else {
        result(
          FlutterError(
            code: "zoom_service_missing",
            message: "Zoom MeetingService is not available",
            details: nil
          )
        )
        return
      }

      let joinParam = MobileRTCMeetingJoinParam()
      joinParam.meetingNumber = meetingId
      joinParam.password = password
      joinParam.userName = displayName.isEmpty ? "Lingufranca" : displayName

      let joinResult = meetingService.joinMeeting(with: joinParam)
      if joinResult == .success {
        result(["status": "joined"])
        return
      }

      result(
        FlutterError(
          code: "zoom_join_failed",
          message: "Zoom join failed: \(joinResult.rawValue)",
          details: nil
        )
      )
    }
  }

  private func ensureZoomPermissions(completion: @escaping (Bool) -> Void) {
    requestAccess(for: .video) { videoGranted in
      guard videoGranted else {
        completion(false)
        return
      }

      self.requestAccess(for: .audio) { audioGranted in
        completion(audioGranted)
      }
    }
  }

  private func requestAccess(
    for mediaType: AVMediaType,
    completion: @escaping (Bool) -> Void
  ) {
    switch AVCaptureDevice.authorizationStatus(for: mediaType) {
    case .authorized:
      completion(true)
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: mediaType) { granted in
        DispatchQueue.main.async {
          completion(granted)
        }
      }
    case .denied, .restricted:
      completion(false)
    @unknown default:
      completion(false)
    }
  }

  private func isZoomAuthorized() -> Bool {
    let sdk = MobileRTC.shared()
    return sdk.isRTCAuthorized()
  }

  private func flushZoomInitFailure(code: String, message: String) {
    zoomInitInProgress = false
    let results = pendingZoomInitResults
    pendingZoomInitResults.removeAll()
    for result in results {
      result(FlutterError(code: code, message: message, details: nil))
    }
  }

  private func currentFlutterController() -> FlutterViewController? {
    return window?.rootViewController as? FlutterViewController
  }

  private func presentableRootController() -> UIViewController? {
    if let presented = window?.rootViewController?.presentedViewController {
      return presented
    }
    return window?.rootViewController
  }
}
