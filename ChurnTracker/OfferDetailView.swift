import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct OfferDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let offer: ChurnOffer

    @State private var showingEdit = false
    @State private var selectedItems: [PhotosPickerItem] = []

    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("Bank", value: offer.bankName)
                LabeledContent("Offer", value: offer.offerName)
                LabeledContent("Status", value: offer.status.rawValue)
                LabeledContent("Bonus", value: offer.bonusAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                LabeledContent("Next action", value: offer.nextAction)
                if let expectedPayoutDate = offer.expectedPayoutDate {
                    LabeledContent("Expected payout", value: expectedPayoutDate.formatted(date: .abbreviated, time: .omitted))
                }
            }

            Section("Requirements") {
                if offer.requirements.isEmpty {
                    Text("No requirements yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(offer.requirements) { requirement in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(requirement.title)
                                    .font(.headline)

                                Spacer()

                                Button {
                                    toggle(requirement)
                                } label: {
                                    Image(systemName: requirement.isComplete ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(requirement.isComplete ? .green : .secondary)
                                }
                                .buttonStyle(.plain)
                            }

                            Text(requirement.progressSummary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if let dueDate = requirement.dueDate {
                                Text("Due \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Section("Dates") {
                if let applicationDate = offer.applicationDate {
                    LabeledContent("Applied", value: applicationDate.formatted(date: .abbreviated, time: .omitted))
                }
                if let openedDate = offer.openedDate {
                    LabeledContent("Opened", value: openedDate.formatted(date: .abbreviated, time: .omitted))
                }
                if let deadlineDate = offer.deadlineDate {
                    LabeledContent("Deadline", value: deadlineDate.formatted(date: .abbreviated, time: .omitted))
                }
                if let closureEligibleDate = offer.closureEligibleDate {
                    LabeledContent("Safe to close", value: closureEligibleDate.formatted(date: .abbreviated, time: .omitted))
                }
            }

            if !offer.promoCode.isEmpty || !offer.offerURL.isEmpty {
                Section("Promo & Link") {
                    if !offer.promoCode.isEmpty {
                        LabeledContent("Promo code", value: offer.promoCode)
                    }

                    if let url = URL(string: offer.offerURL), !offer.offerURL.isEmpty {
                        Link(destination: url) {
                            Label("Open offer link", systemImage: "link")
                        }
                    }
                }
            }

            if !offer.attachments.isEmpty {
                Section("Screenshots") {
                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            ForEach(offer.attachments) { attachment in
                                if let image = UIImage(contentsOfFile: attachment.localPath) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 150, height: 110)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))

                                        Text(attachment.fileName)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 150)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if !offer.notes.isEmpty {
                Section("Notes") {
                    Text(offer.notes)
                }
            }

            if !offer.events.isEmpty {
                Section("History") {
                    ForEach(offer.events.sorted(by: { $0.date > $1.date })) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title)
                                .font(.headline)
                            Text(event.type.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !event.details.isEmpty {
                                Text(event.details)
                                    .font(.subheadline)
                            }
                            Text(event.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle(offer.offerName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 5, matching: .images) {
                    Image(systemName: "photo.badge.plus")
                }

                Button("Edit") {
                    showingEdit = true
                }
            }
        }
        .onChange(of: selectedItems) { _, newItems in
            Task {
                await importAttachments(from: newItems)
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                OfferEditorView(offer: offer)
            }
        }
    }

    private func toggle(_ requirement: Requirement) {
        requirement.isComplete.toggle()
        requirement.completionDate = requirement.isComplete ? .now : nil
        requirement.offer?.touch()

        if requirement.isComplete {
            offer.addEvent(.requirementCompleted, title: "Completed \(requirement.title)")
        }

        if offer.requirements.allSatisfy(\.isComplete) && !offer.requirements.isEmpty && offer.status == .inProgress {
            offer.status = .waitingForBonus
        }

        try? modelContext.save()
    }

    private func importAttachments(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }

        for item in items {
            do {
                if let attachment = try await AttachmentStore.shared.importAttachment(from: item, for: offer) {
                    offer.attachments.append(attachment)
                }
            } catch {
                print("Attachment import failed: \(error)")
            }
        }

        offer.addEvent(.noteAdded, title: "Added screenshot attachment")
        try? modelContext.save()
        selectedItems = []
    }
}
