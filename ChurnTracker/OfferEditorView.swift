import SwiftUI
import SwiftData

struct OfferEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let offer: ChurnOffer?

    @State private var bankName = ""
    @State private var offerName = ""
    @State private var accountType: AccountType = .checking
    @State private var status: OfferStatus = .researching
    @State private var applicationDate = Date.now
    @State private var openedDate = Date.now
    @State private var deadlineDate = Date.now
    @State private var expectedPayoutDate = Date.now
    @State private var closureEligibleDate = Date.now
    @State private var bonusAmount = 0.0
    @State private var monthlyFee = 0.0
    @State private var includeApplicationDate = false
    @State private var includeOpenedDate = false
    @State private var includeDeadlineDate = false
    @State private var includeExpectedPayoutDate = false
    @State private var includeClosureEligibleDate = false
    @State private var hasMonthlyFee = false
    @State private var monthlyFeeWaiverNotes = ""
    @State private var offerURL = ""
    @State private var promoCode = ""
    @State private var notes = ""

    init(offer: ChurnOffer? = nil) {
        self.offer = offer
    }

    var body: some View {
        Form {
            Section("Bank") {
                TextField("Bank name", text: $bankName)
                TextField("Offer name", text: $offerName)
                Picker("Account type", selection: $accountType) {
                    ForEach(AccountType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                Picker("Status", selection: $status) {
                    ForEach(OfferStatus.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
            }

            Section("Money") {
                TextField("Bonus amount", value: $bonusAmount, format: .number)
                    .keyboardType(.decimalPad)

                Toggle("Monthly fee", isOn: $hasMonthlyFee)

                if hasMonthlyFee {
                    TextField("Monthly fee amount", value: $monthlyFee, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Waiver notes", text: $monthlyFeeWaiverNotes, axis: .vertical)
                }
            }

            Section("Dates") {
                Toggle("Track application date", isOn: $includeApplicationDate)
                if includeApplicationDate {
                    DatePicker("Application", selection: $applicationDate, displayedComponents: .date)
                }

                Toggle("Track opened date", isOn: $includeOpenedDate)
                if includeOpenedDate {
                    DatePicker("Opened", selection: $openedDate, displayedComponents: .date)
                }

                Toggle("Track deadline", isOn: $includeDeadlineDate)
                if includeDeadlineDate {
                    DatePicker("Deadline", selection: $deadlineDate, displayedComponents: .date)
                }

                Toggle("Track expected payout", isOn: $includeExpectedPayoutDate)
                if includeExpectedPayoutDate {
                    DatePicker("Expected payout", selection: $expectedPayoutDate, displayedComponents: .date)
                }

                Toggle("Track safe close date", isOn: $includeClosureEligibleDate)
                if includeClosureEligibleDate {
                    DatePicker("Safe close date", selection: $closureEligibleDate, displayedComponents: .date)
                }
            }

            Section("Linking") {
                TextField("Offer URL", text: $offerURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("Promo code", text: $promoCode)
                    .textInputAutocapitalization(.characters)
            }

            Section("Notes") {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(4...8)
            }
        }
        .navigationTitle(offer == nil ? "New Offer" : "Edit Offer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    save()
                }
                .disabled(bankName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || offerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear(perform: loadExistingOffer)
    }

    private func loadExistingOffer() {
        guard let offer else { return }

        bankName = offer.bankName
        offerName = offer.offerName
        accountType = offer.accountType
        status = offer.status
        bonusAmount = offer.bonusAmount
        monthlyFee = offer.monthlyFee ?? 0
        hasMonthlyFee = offer.monthlyFee != nil
        monthlyFeeWaiverNotes = offer.monthlyFeeWaiverNotes
        offerURL = offer.offerURL
        promoCode = offer.promoCode
        notes = offer.notes

        if let applicationDateValue = offer.applicationDate {
            includeApplicationDate = true
            applicationDate = applicationDateValue
        }

        if let openedDateValue = offer.openedDate {
            includeOpenedDate = true
            openedDate = openedDateValue
        }

        if let deadlineDateValue = offer.deadlineDate {
            includeDeadlineDate = true
            deadlineDate = deadlineDateValue
        }

        if let expectedPayoutDateValue = offer.expectedPayoutDate {
            includeExpectedPayoutDate = true
            expectedPayoutDate = expectedPayoutDateValue
        }

        if let closureEligibleDateValue = offer.closureEligibleDate {
            includeClosureEligibleDate = true
            closureEligibleDate = closureEligibleDateValue
        }
    }

    private func save() {
        let target = offer ?? ChurnOffer(
            bankName: bankName,
            offerName: offerName
        )

        target.bankName = bankName.trimmingCharacters(in: .whitespacesAndNewlines)
        target.offerName = offerName.trimmingCharacters(in: .whitespacesAndNewlines)
        target.accountType = accountType
        target.status = status
        target.applicationDate = includeApplicationDate ? applicationDate : nil
        target.openedDate = includeOpenedDate ? openedDate : nil
        target.deadlineDate = includeDeadlineDate ? deadlineDate : nil
        target.expectedPayoutDate = includeExpectedPayoutDate ? expectedPayoutDate : nil
        target.closureEligibleDate = includeClosureEligibleDate ? closureEligibleDate : nil
        target.bonusAmount = bonusAmount
        target.monthlyFee = hasMonthlyFee ? monthlyFee : nil
        target.monthlyFeeWaiverNotes = monthlyFeeWaiverNotes
        target.offerURL = offerURL.trimmingCharacters(in: .whitespacesAndNewlines)
        target.promoCode = promoCode.trimmingCharacters(in: .whitespacesAndNewlines)
        target.notes = notes
        target.touch()

        if offer == nil {
            target.addEvent(.opened, title: "Offer created")
            modelContext.insert(target)

            if target.requirements.isEmpty {
                target.requirements.append(Requirement(
                    type: .other,
                    title: "Primary churn requirement",
                    targetValue: 1,
                    currentValue: 0,
                    unit: .count,
                    dueDate: target.deadlineDate,
                    offer: target
                ))
            }
        }

        try? modelContext.save()
        NotificationManager.shared.scheduleNotifications(for: target)
        dismiss()
    }
}
