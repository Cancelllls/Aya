import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

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

        channel.setMethodCallHandler { (call, result) in
            switch call.method {
            case "getAndroidSdkVersion":
                let version = ProcessInfo.processInfo.operatingSystemVersion
                result(version.majorVersion)

            case "checkExactAlarmPermission",
                 "requestExactAlarmPermission",
                 "checkNotificationPolicyAccess",
                 "requestNotificationPolicyAccess":
                result(true)

            case "setKeepScreenOn":
                if let args = call.arguments as? [String: Any],
                   let enabled = args["enabled"] as? Bool {
                    DispatchQueue.main.async {
                        UIApplication.shared.isIdleTimerDisabled = enabled
                    }
                }
                result(true)

            case "updateWidget":
                result(true)

            case "getTimeZoneName":
                result(TimeZone.current.identifier)

            case "stopAdhan":
                result(true)

            default:
                result(FlutterMethodNotImplemented)
            }
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
            case "scheduleExactAlarm",
                 "schedulePreAdhanAlarm",
                 "cancelAlarm",
                 "cancelAllAlarms",
                 "openOemAutoStartSettings":
                result(true)

            case "getScheduledAlarms":
                result([])

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
