import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("didSeedSampleData") private var didSeedSampleData = false
    @State private var notificationStatus = "Unknown"

    var body: some View {
        NavigationStack {
            List {
                Section("Notifications") {
                    LabeledContent("Permission", value: notificationStatus)

                    Button("Request Permission") {
                        Task {
                            await NotificationManager.shared.requestAuthorization()
                            await refreshStatus()
                        }
                    }
                }

                Section("Data") {
                    Button("Insert Sample Offers") {
                        do {
                            try SampleData.insertIfNeeded(in: modelContext)
                            didSeedSampleData = true
                        } catch {
                            print("Failed to insert sample data: \(error)")
                        }
                    }
                }

                Section("About") {
                    Text("Churn Tracker is an iPhone-only SwiftUI app for managing personal bank-churning workflows.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
        .task {
            await refreshStatus()
        }
    }

    private func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            notificationStatus = "Enabled"
        case .denied:
            notificationStatus = "Denied"
        case .notDetermined:
            notificationStatus = "Not requested"
        @unknown default:
            notificationStatus = "Unknown"
        }
    }
}
