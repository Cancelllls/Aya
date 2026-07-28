import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    private var speechSynthesizer: AVSpeechSynthesizer?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if let controller = window?.rootViewController as? FlutterViewController {
            registerSystemChannel(with: controller)
            registerAlarmChannel(with: controller)
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }

    // MARK: - com.quran.aya/system Channel

    private func registerSystemChannel(with controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: "com.quran.aya/system",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else {
                result(FlutterMethodNotImplemented)
                return
            }
            self.handleSystemMethod(call: call, result: result)
        }
    }

    private func handleSystemMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getAndroidSdkVersion":
            let version = ProcessInfo.processInfo.operatingSystemVersion
            result(version.majorVersion)

        case "checkExactAlarmPermission":
            result(true)

        case "requestExactAlarmPermission":
            result(true)

        case "checkBatteryOptimization":
            result(true)

        case "requestDisableBatteryOptimization":
            result(true)

        case "setKeepScreenOn":
            if let args = call.arguments as? [String: Any],
               let enabled = args["enabled"] as? Bool {
                DispatchQueue.main.async {
                    UIApplication.shared.isIdleTimerDisabled = enabled
                }
            }
            result(true)

        case "startLockTask":
            result(true)

        case "stopLockTask":
            result(true)

        case "vibrate":
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            result(true)

        case "speak":
            guard let args = call.arguments as? [String: Any],
                  let text = args["text"] as? String else {
                result(false)
                return
            }
            let lang = args["lang"] as? String ?? "ar"
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: lang)
            utterance.rate = 0.5

            if speechSynthesizer == nil {
                speechSynthesizer = AVSpeechSynthesizer()
            }
            speechSynthesizer?.stopSpeaking(at: .immediate)
            speechSynthesizer?.speak(utterance)
            result(true)

        case "updateWidget":
            result(true)

        case "getTimeZoneName":
            result(TimeZone.current.identifier)

        case "stopAdhan":
            speechSynthesizer?.stopSpeaking(at: .immediate)
            result(true)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - com.adhan.app/alarm Channel

    private func registerAlarmChannel(with controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: "com.adhan.app/alarm",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { (call, result) in
            switch call.method {
            case "scheduleExactAlarm":
                result(true)

            case "openOemAutoStartSettings":
                result(true)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
