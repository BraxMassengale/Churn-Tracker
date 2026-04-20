import SwiftUI
import SwiftData

@main
struct ChurnTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: [
            ChurnOffer.self,
            Requirement.self,
            OfferEvent.self,
            OfferAttachment.self
        ])
    }
}
