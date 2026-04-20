import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: [SortDescriptor(\ChurnOffer.updatedAt, order: .reverse)]) private var offers: [ChurnOffer]

    private var overdueOffers: [ChurnOffer] {
        offers.filter { $0.isOverdue && !$0.isArchived }
    }

    private var dueSoonOffers: [ChurnOffer] {
        offers.filter {
            guard !$0.isArchived, let date = $0.nearestActionDate else { return false }
            return date >= Calendar.current.startOfDay(for: .now) && date <= Calendar.current.date(byAdding: .day, value: 7, to: .now)!
        }
        .sorted { ($0.nearestActionDate ?? .distantFuture) < ($1.nearestActionDate ?? .distantFuture) }
    }

    private var waitingOffers: [ChurnOffer] {
        offers.filter { $0.status == .waitingForBonus && !$0.isArchived }
    }

    private var readyToCloseOffers: [ChurnOffer] {
        offers.filter { $0.canBeClosed && !$0.isArchived }
    }

    var body: some View {
        NavigationStack {
            List {
                if offers.isEmpty {
                    ContentUnavailableView(
                        "No offers yet",
                        systemImage: "tray",
                        description: Text("Add your first churn offer to start tracking what comes next.")
                    )
                }

                if !overdueOffers.isEmpty {
                    Section("Overdue") {
                        ForEach(overdueOffers) { offer in
                            NavigationLink {
                                OfferDetailView(offer: offer)
                            } label: {
                                OfferRowView(offer: offer, tint: .red)
                            }
                        }
                    }
                }

                if !dueSoonOffers.isEmpty {
                    Section("Do This Week") {
                        ForEach(dueSoonOffers) { offer in
                            NavigationLink {
                                OfferDetailView(offer: offer)
                            } label: {
                                OfferRowView(offer: offer, tint: .orange)
                            }
                        }
                    }
                }

                if !waitingOffers.isEmpty {
                    Section("Waiting for Payout") {
                        ForEach(waitingOffers) { offer in
                            NavigationLink {
                                OfferDetailView(offer: offer)
                            } label: {
                                OfferRowView(offer: offer, tint: .blue)
                            }
                        }
                    }
                }

                if !readyToCloseOffers.isEmpty {
                    Section("Ready to Close") {
                        ForEach(readyToCloseOffers) { offer in
                            NavigationLink {
                                OfferDetailView(offer: offer)
                            } label: {
                                OfferRowView(offer: offer, tint: .green)
                            }
                        }
                    }
                }

                Section("Quick Stats") {
                    LabeledContent("Active offers", value: "\(offers.filter { $0.status != .closed && !$0.isArchived }.count)")
                    LabeledContent("Pending bonus", value: offers.filter { !$0.isArchived }.pendingBonusCurrency)
                    LabeledContent("Completed bonus", value: offers.filter { !$0.isArchived }.earnedBonusCurrency)
                }
            }
            .navigationTitle("What’s Next")
        }
    }
}

private struct OfferRowView: View {
    let offer: ChurnOffer
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(offer.displayName)
                .font(.headline)

            Text(offer.nextAction)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Text(offer.status.rawValue)
                Spacer()
                if let date = offer.nearestActionDate {
                    Text(date, style: .date)
                }
            }
            .font(.caption)
            .foregroundStyle(tint)
        }
        .padding(.vertical, 2)
    }
}

private extension Array where Element == ChurnOffer {
    var pendingBonusCurrency: String {
        currency(total: reduce(0) { $0 + $1.pendingBonusAmount })
    }

    var earnedBonusCurrency: String {
        currency(total: reduce(0) { partial, offer in
            partial + (offer.actualPayoutDate != nil ? offer.bonusAmount : 0)
        })
    }

    private func currency(total: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: total as NSNumber) ?? "$0"
    }
}
