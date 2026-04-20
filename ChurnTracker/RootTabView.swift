import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("didSeedSampleData") private var didSeedSampleData = false

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "checklist")
                }

            OffersView()
                .tabItem {
                    Label("Offers", systemImage: "building.columns")
                }

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .task {
            guard !didSeedSampleData else { return }
            do {
                try SampleData.insertIfNeeded(in: modelContext)
                didSeedSampleData = true
            } catch {
                print("Failed to seed sample data: \(error)")
            }
        }
    }
}
