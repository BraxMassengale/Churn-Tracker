import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var offers: [ChurnOffer]
    @State private var notificationStatus = "Unknown"

    private var canInsertSampleData: Bool {
        offers.isEmpty
    }

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
                        } catch {
                            print("Failed to insert sample data: \(error)")
                        }
                    }
                    .disabled(!canInsertSampleData)

                    Text(canInsertSampleData ? "Sample offers are optional and only insert into an empty tracker." : "Sample offers are only available before you add real offers.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
