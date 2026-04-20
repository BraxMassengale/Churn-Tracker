import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Query private var offers: [ChurnOffer]

    private var activeOffers: [ChurnOffer] {
        offers.filter { $0.status != .closed && !$0.isArchived }
    }

    private var totalEarned: Double {
        offers.reduce(0) { partial, offer in
            partial + (offer.actualPayoutDate != nil ? offer.bonusAmount : 0)
        }
    }

    private var pendingTotal: Double {
        offers.reduce(0) { $0 + $1.pendingBonusAmount }
    }

    private var averagePayoutDays: Int {
        let days = offers.compactMap { offer -> Int? in
            guard let opened = offer.openedDate, let actual = offer.actualPayoutDate else { return nil }
            return Calendar.current.dateComponents([.day], from: opened, to: actual).day
        }

        guard !days.isEmpty else { return 0 }
        return days.reduce(0, +) / days.count
    }

    private var groupedByBank: [(String, Double)] {
        Dictionary(grouping: offers, by: \.bankName)
            .map { key, value in
                (key, value.reduce(0) { $0 + $1.bonusAmount })
            }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Summary") {
                    LabeledContent("Total earned", value: totalEarned, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    LabeledContent("Pending bonuses", value: pendingTotal, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    LabeledContent("Active offers", value: "\(activeOffers.count)")
                    LabeledContent("Average payout time", value: averagePayoutDays == 0 ? "—" : "\(averagePayoutDays) days")
                }

                if !groupedByBank.isEmpty {
                    Section("By Bank") {
                        ForEach(groupedByBank, id: \.0) { bank, total in
                            LabeledContent(bank, value: total, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        }
                    }
                }
            }
            .navigationTitle("Analytics")
        }
    }
}
