import UIKit
import Flutter
import WatchConnectivity

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, WCSessionDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Initialize and activate WCSession
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }

        let controller = window?.rootViewController as! FlutterViewController
        let healthKitChannel = FlutterMethodChannel(name: "com.example.yourapp/healthkit", binaryMessenger: controller.binaryMessenger)

        healthKitChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            if call.method == "getHeartRate" {
                self.requestHeartRateFromWatch(result: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func requestHeartRateFromWatch(result: @escaping FlutterResult) {
        // Send a message to the Watch app to start heart rate monitoring
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["request": "getHeartRate"], replyHandler: { response in
                if let heartRate = response["heartRate"] as? Double {
                    result(heartRate)
                } else {
                    result(FlutterError(code: "NO_DATA", message: "No heart rate data available", details: nil))
                }
            }) { error in
                result(FlutterError(code: "WATCH_ERROR", message: "Failed to communicate with Watch app", details: error.localizedDescription))
            }
        } else {
            result(FlutterError(code: "NOT_REACHABLE", message: "Watch app is not reachable", details: nil))
        }
    }

    // MARK: - WCSessionDelegate methods

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // This method is required but can be left empty if you don't need to handle inactivity
    }

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        if session.isWatchAppInstalled {
            print("Watch app is installed")
        } else {
            print("Watch app is not installed")
        }
    }


    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let heartRate = message["heartRate"] as? Double {
            let controller = window?.rootViewController as? FlutterViewController
            let healthKitChannel = FlutterMethodChannel(name: "com.example.yourapp/healthkit", binaryMessenger: controller!.binaryMessenger)
            healthKitChannel.invokeMethod("heartRateUpdated", arguments: heartRate)
        }
    }
}
