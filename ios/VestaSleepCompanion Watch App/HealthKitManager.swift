import Foundation
import HealthKit
import WatchConnectivity

class HealthKitManager: NSObject, ObservableObject, WCSessionDelegate {
    private let healthStore = HKHealthStore()
    @Published var heartRate: Double = 0.0

    override init() {
        super.init()
        requestAuthorization { [weak self] success, error in
            if success {
                self?.startHeartRateMonitoring()
            } else {
                print("HealthKit authorization failed: \(String(describing: error))")
            }
        }
    }

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(false, NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Heart rate data type not available"]))
            return
        }

        healthStore.requestAuthorization(toShare: nil, read: [heartRateType], completion: completion)
    }

    func startHeartRateMonitoring() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        // Set up a live query for continuous heart rate updates
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] (query, samples, deletedObjects, anchor, error) in
            self?.handleHeartRateSamples(samples)
        }

        query.updateHandler = { [weak self] (query, samples, deletedObjects, anchor, error) in
            self?.handleHeartRateSamples(samples)
        }

        healthStore.execute(query)
    }

    private func handleHeartRateSamples(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else { return }
        if let lastSample = heartRateSamples.last {
            let heartRateUnit = HKUnit(from: "count/min")
            let heartRateValue = lastSample.quantity.doubleValue(for: heartRateUnit)
            DispatchQueue.main.async {
                self.heartRate = heartRateValue
                self.sendHeartRateToPhone(heartRateValue)
            }
        }
    }

    private func sendHeartRateToPhone(_ heartRate: Double) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["heartRate": heartRate], replyHandler: nil) { error in
                print("Error sending heart rate to phone: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - WCSessionDelegate Methods

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        }
    }
}
