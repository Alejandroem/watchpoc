import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager

    var body: some View {
        VStack {
            Text("Heart Rate")
                .font(.headline)
            Text("\(Int(healthKitManager.heartRate)) bpm")
                .font(.largeTitle)
                .foregroundColor(.red)
        }
        .padding()
    }
}
