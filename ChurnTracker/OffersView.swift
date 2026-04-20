import SwiftUI
import SwiftData

struct OffersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\ChurnOffer.bankName), SortDescriptor(\ChurnOffer.offerName)]) private var offers: [ChurnOffer]

    @State private var showingAddOffer = false
    @State private var searchText = ""
    @State private var filter: OfferFilter = .active

    private var filteredOffers: [ChurnOffer] {
        offers.filter { offer in
            let matchesSearch = searchText.isEmpty ||
                offer.bankName.localizedCaseInsensitiveContains(searchText) ||
                offer.offerName.localizedCaseInsensitiveContains(searchText)

            let matchesFilter: Bool
            switch filter {
            case .all:
                matchesFilter = !offer.isArchived
            case .active:
                matchesFilter = offer.status != .closed && !offer.isArchived
            case .waiting:
                matchesFilter = offer.status == .waitingForBonus && !offer.isArchived
            case .readyToClose:
                matchesFilter = offer.canBeClosed && !offer.isArchived
            case .closed:
                matchesFilter = offer.status == .closed && !offer.isArchived
            }

            return matchesSearch && matchesFilter
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Picker("Filter", selection: $filter) {
                    ForEach(OfferFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                ForEach(filteredOffers) { offer in
                    NavigationLink {
                        OfferDetailView(offer: offer)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(offer.displayName)
                                .font(.headline)

                            Text(offer.progressText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            HStack {
                                Text(offer.status.rawValue)
                                Spacer()
                                Text(offer.bonusAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteOffers)
            }
            .navigationTitle("Offers")
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddOffer = true
                    } label: {
                        Label("Add Offer", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddOffer) {
                NavigationStack {
                    OfferEditorView()
                }
            }
        }
    }

    private func deleteOffers(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredOffers[index])
        }

        try? modelContext.save()
    }
}

enum OfferFilter: String, CaseIterable, Identifiable {
    case active = "Active"
    case waiting = "Waiting"
    case readyToClose = "Close"
    case closed = "Closed"
    case all = "All"

    var id: String { rawValue }
}
