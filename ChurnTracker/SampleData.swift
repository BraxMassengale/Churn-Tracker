import Foundation
import SwiftData

enum SampleData {
    static func insertIfNeeded(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<ChurnOffer>()
        let existing = try context.fetch(descriptor)
        guard existing.isEmpty else { return }

        let chase = ChurnOffer(
            bankName: "Chase",
            offerName: "Total Checking Bonus",
            accountType: .checking,
            status: .inProgress,
            applicationDate: .now.addingTimeInterval(-86400 * 25),
            openedDate: .now.addingTimeInterval(-86400 * 22),
            deadlineDate: .now.addingTimeInterval(86400 * 18),
            bonusAmount: 300,
            expectedPayoutDate: .now.addingTimeInterval(86400 * 40),
            closureEligibleDate: .now.addingTimeInterval(86400 * 160),
            monthlyFee: 12,
            monthlyFeeWaiverNotes: "Keep qualifying direct deposit active.",
            offerURL: "https://www.chase.com",
            promoCode: "CHASE300",
            notes: "Opened for personal churning cycle."
        )
        chase.requirements.append(Requirement(
            type: .directDeposit,
            title: "Qualifying direct deposit",
            targetValue: 1,
            currentValue: 0,
            unit: .count,
            dueDate: .now.addingTimeInterval(86400 * 18),
            offer: chase
        ))
        chase.requirements.append(Requirement(
            type: .debitTransactions,
            title: "Debit card purchases",
            targetValue: 10,
            currentValue: 4,
            unit: .count,
            dueDate: .now.addingTimeInterval(86400 * 18),
            offer: chase
        ))
        chase.addEvent(.opened, title: "Account opened")
        chase.addEvent(.requirementProgress, title: "Logged 4 debit card purchases")

        let discover = ChurnOffer(
            bankName: "Discover",
            offerName: "Online Savings Bonus",
            accountType: .savings,
            status: .waitingForBonus,
            applicationDate: .now.addingTimeInterval(-86400 * 60),
            openedDate: .now.addingTimeInterval(-86400 * 58),
            deadlineDate: .now.addingTimeInterval(-86400 * 15),
            bonusAmount: 200,
            expectedPayoutDate: .now.addingTimeInterval(86400 * 7),
            closureEligibleDate: .now.addingTimeInterval(86400 * 120),
            offerURL: "https://www.discover.com",
            notes: "Requirements done. Waiting for payout."
        )
        discover.requirements.append(Requirement(
            type: .balanceHold,
            title: "Fund minimum balance",
            targetValue: 15000,
            currentValue: 15000,
            unit: .dollars,
            dueDate: .now.addingTimeInterval(-86400 * 15),
            isComplete: true,
            completionDate: .now.addingTimeInterval(-86400 * 20),
            offer: discover
        ))
        discover.addEvent(.requirementCompleted, title: "Funding requirement completed")
        discover.addEvent(.noteAdded, title: "Waiting for bonus payout")

        context.insert(chase)
        context.insert(discover)
        try context.save()
    }
}
