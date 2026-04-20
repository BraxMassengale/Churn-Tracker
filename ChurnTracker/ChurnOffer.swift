import Foundation
import SwiftData

enum AccountType: String, Codable, CaseIterable, Identifiable {
    case checking = "Checking"
    case savings = "Savings"
    case businessChecking = "Business Checking"
    case businessSavings = "Business Savings"
    case other = "Other"

    var id: String { rawValue }
}

enum OfferStatus: String, Codable, CaseIterable, Identifiable {
    case researching = "Researching"
    case applied = "Applied"
    case opened = "Opened"
    case inProgress = "In Progress"
    case waitingForBonus = "Waiting for Bonus"
    case bonusReceived = "Bonus Received"
    case readyToClose = "Ready to Close"
    case closed = "Closed"

    var id: String { rawValue }
}

enum RequirementType: String, Codable, CaseIterable, Identifiable {
    case directDeposit = "Direct Deposit"
    case debitTransactions = "Debit Transactions"
    case balanceHold = "Balance Hold"
    case billPay = "Bill Pay"
    case other = "Other"

    var id: String { rawValue }
}

enum RequirementUnit: String, Codable, CaseIterable, Identifiable {
    case count = "Count"
    case dollars = "Dollars"
    case days = "Days"
    case yesNo = "Yes / No"

    var id: String { rawValue }
}

enum OfferEventType: String, Codable, CaseIterable, Identifiable {
    case applied = "Applied"
    case approved = "Approved"
    case opened = "Opened"
    case requirementProgress = "Requirement Progress"
    case requirementCompleted = "Requirement Completed"
    case bonusReceived = "Bonus Received"
    case feeCharged = "Fee Charged"
    case feeWaived = "Fee Waived"
    case noteAdded = "Note Added"
    case closed = "Closed"

    var id: String { rawValue }
}

@Model
final class ChurnOffer {
    var bankName: String
    var offerName: String
    var accountType: AccountType
    var status: OfferStatus
    var applicationDate: Date?
    var openedDate: Date?
    var deadlineDate: Date?
    var bonusAmount: Double
    var expectedPayoutDate: Date?
    var actualPayoutDate: Date?
    var closureEligibleDate: Date?
    var closedDate: Date?
    var monthlyFee: Double?
    var monthlyFeeWaiverNotes: String
    var offerURL: String
    var promoCode: String
    var notes: String
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Requirement.offer)
    var requirements: [Requirement]

    @Relationship(deleteRule: .cascade, inverse: \OfferEvent.offer)
    var events: [OfferEvent]

    @Relationship(deleteRule: .cascade, inverse: \OfferAttachment.offer)
    var attachments: [OfferAttachment]

    init(
        bankName: String,
        offerName: String,
        accountType: AccountType = .checking,
        status: OfferStatus = .researching,
        applicationDate: Date? = nil,
        openedDate: Date? = nil,
        deadlineDate: Date? = nil,
        bonusAmount: Double = 0,
        expectedPayoutDate: Date? = nil,
        actualPayoutDate: Date? = nil,
        closureEligibleDate: Date? = nil,
        closedDate: Date? = nil,
        monthlyFee: Double? = nil,
        monthlyFeeWaiverNotes: String = "",
        offerURL: String = "",
        promoCode: String = "",
        notes: String = "",
        isArchived: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.bankName = bankName
        self.offerName = offerName
        self.accountType = accountType
        self.status = status
        self.applicationDate = applicationDate
        self.openedDate = openedDate
        self.deadlineDate = deadlineDate
        self.bonusAmount = bonusAmount
        self.expectedPayoutDate = expectedPayoutDate
        self.actualPayoutDate = actualPayoutDate
        self.closureEligibleDate = closureEligibleDate
        self.closedDate = closedDate
        self.monthlyFee = monthlyFee
        self.monthlyFeeWaiverNotes = monthlyFeeWaiverNotes
        self.offerURL = offerURL
        self.promoCode = promoCode
        self.notes = notes
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.requirements = []
        self.events = []
        self.attachments = []
    }
}

extension ChurnOffer {
    var displayName: String {
        "\(bankName) · \(offerName)"
    }

    var isOverdue: Bool {
        guard let deadlineDate else { return false }
        return deadlineDate < Calendar.current.startOfDay(for: .now) && !isAllRequirementsComplete
    }

    var isAllRequirementsComplete: Bool {
        !requirements.isEmpty && requirements.allSatisfy(\.isComplete)
    }

    var progressText: String {
        guard !requirements.isEmpty else { return "No requirements" }
        let completed = requirements.filter(\.isComplete).count
        return "\(completed)/\(requirements.count) complete"
    }

    var progressValue: Double {
        guard !requirements.isEmpty else { return 0 }
        return Double(requirements.filter(\.isComplete).count) / Double(requirements.count)
    }

    var nextAction: String {
        if status == .closed { return "Closed" }
        if let overdueRequirement = requirements.first(where: { !$0.isComplete && ($0.dueDate ?? .distantFuture) < .now }) {
            return "Finish overdue: \(overdueRequirement.title)"
        }
        if let requirement = requirements
            .filter({ !$0.isComplete })
            .sorted(by: { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) })
            .first {
            return "Complete: \(requirement.title)"
        }
        if status == .waitingForBonus {
            return "Wait for bonus payout"
        }
        if status == .bonusReceived || status == .readyToClose {
            return "Review closure timing"
        }
        return "Review offer"
    }

    var nearestActionDate: Date? {
        let requirementDates = requirements.compactMap(\.dueDate)
        return ([deadlineDate, expectedPayoutDate, closureEligibleDate] + requirementDates).compactMap { $0 }.sorted().first
    }

    var canBeClosed: Bool {
        guard status != .closed else { return false }
        guard let closureEligibleDate else { return false }
        return closureEligibleDate <= .now
    }

    var pendingBonusAmount: Double {
        actualPayoutDate == nil ? bonusAmount : 0
    }

    func touch() {
        updatedAt = .now
    }

    func addEvent(_ type: OfferEventType, title: String, details: String = "", at date: Date = .now) {
        events.append(OfferEvent(date: date, type: type, title: title, details: details, offer: self))
        touch()
    }
}

@Model
final class Requirement {
    var type: RequirementType
    var title: String
    var targetValue: Int?
    var currentValue: Int?
    var unit: RequirementUnit
    var dueDate: Date?
    var isComplete: Bool
    var completionDate: Date?
    var notes: String

    var offer: ChurnOffer?

    init(
        type: RequirementType,
        title: String,
        targetValue: Int? = nil,
        currentValue: Int? = nil,
        unit: RequirementUnit = .count,
        dueDate: Date? = nil,
        isComplete: Bool = false,
        completionDate: Date? = nil,
        notes: String = "",
        offer: ChurnOffer? = nil
    ) {
        self.type = type
        self.title = title
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.unit = unit
        self.dueDate = dueDate
        self.isComplete = isComplete
        self.completionDate = completionDate
        self.notes = notes
        self.offer = offer
    }

    var progressSummary: String {
        guard let targetValue else {
            return isComplete ? "Done" : "Pending"
        }
        let current = currentValue ?? 0
        return "\(current)/\(targetValue)"
    }
}

@Model
final class OfferEvent {
    var date: Date
    var type: OfferEventType
    var title: String
    var details: String

    var offer: ChurnOffer?

    init(date: Date = .now, type: OfferEventType, title: String, details: String = "", offer: ChurnOffer? = nil) {
        self.date = date
        self.type = type
        self.title = title
        self.details = details
        self.offer = offer
    }
}

@Model
final class OfferAttachment {
    var fileName: String
    var localPath: String
    var createdAt: Date
    var caption: String

    var offer: ChurnOffer?

    init(fileName: String, localPath: String, createdAt: Date = .now, caption: String = "", offer: ChurnOffer? = nil) {
        self.fileName = fileName
        self.localPath = localPath
        self.createdAt = createdAt
        self.caption = caption
        self.offer = offer
    }
}
