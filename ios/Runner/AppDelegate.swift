import UIKit
import Flutter
import WatchConnectivity

@main
@objc class AppDelegate: FlutterAppDelegate {
    var session: WCSession?
  
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        initFlutterChannel()
        
        // Initialize and activate WCSession for Watch connectivity if supported
        if WCSession.isSupported() {
            print("Watch Session Supported")
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        } else {
            print("Watch Session Not Supported on this device")
        }
      
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func initFlutterChannel() {
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "com.example.watchApp",
                binaryMessenger: controller.binaryMessenger
            )
            
            channel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
                guard let self = self else { return }
                
                switch call.method {
                case "flutterToWatch":
                    print("Received flutterToWatch call")
                    self.handleFlutterToWatch(call: call, result: result)
                default:
                    result(FlutterMethodNotImplemented)
                }
            })
        }
    }
    
    private func handleFlutterToWatch(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let watchSession = session, watchSession.isPaired, watchSession.isReachable else {
            print("Watch session is not paired or reachable")
            result(false)
            return
        }
        
        // Safely unwrap arguments from the Flutter call
        guard let methodData = call.arguments as? [String: Any],
              let method = methodData["method"],
              let data = methodData["data"] else {
            print("Invalid arguments received in flutterToWatch call")
            result(false)
            return
        }
        
        // Prepare data to send to the watch app
        let watchData: [String: Any] = ["method": method, "data": data]
        print("Sending data to watch: \(watchData)")
        
        watchSession.sendMessage(watchData, replyHandler: { replyData in
            print("Received reply from watch: \(replyData)")
            result(true)
        }, errorHandler: { error in
            print("Error sending data to watch: \(error.localizedDescription)")
            result(false)
        })
    }
}

extension AppDelegate: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated")
        // Re-activate the session if needed
        session.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let method = message["method"] as? String, let controller = self.window?.rootViewController as? FlutterViewController {
                let channel = FlutterMethodChannel(
                    name: "com.example.watchApp",
                    binaryMessenger: controller.binaryMessenger
                )
                // Safely pass the message from the watch to Flutter
                channel.invokeMethod(method, arguments: message) { result in
                    if let error = result as? FlutterError {
                        print("Failed to send message to Flutter: \(error.message ?? "Unknown error")")
                    }
                }
            } else {
                print("Invalid message received from watch: \(message)")
            }
        }
    }
}
