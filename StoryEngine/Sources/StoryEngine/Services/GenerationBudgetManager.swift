import Foundation

/// A claim on budget, made before a provider call and settled after it.
public struct BudgetReservation: Sendable, Hashable {
    public let id: UUID
    public let estimate: UsageEstimate

    public init(id: UUID, estimate: UsageEstimate) {
        self.id = id
        self.estimate = estimate
    }
}

/// What is left to spend on a story.
public struct BudgetRemaining: Sendable, Hashable {
    public let languageModelCalls: Int
    public let imageCalls: Int
    public let tokens: Int
    public let costUSD: Double

    public init(languageModelCalls: Int, imageCalls: Int, tokens: Int, costUSD: Double) {
        self.languageModelCalls = languageModelCalls
        self.imageCalls = imageCalls
        self.tokens = tokens
        self.costUSD = costUSD
    }

    public var isExhausted: Bool {
        languageModelCalls <= 0 && imageCalls <= 0
    }
}

/// Enforces a story's spending ceilings.
///
/// The important property is that `reserve` is called *before* the provider
/// call and throws rather than reporting after the fact — a budget that only
/// tells you what you already spent is not a budget. Reservations are held
/// until committed, so several calls in flight cannot each see the same
/// headroom.
public actor GenerationBudgetManager {
    private let budget: GenerationBudget
    private var ledger: UsageLedger
    private var outstanding: [UUID: UsageEstimate] = [:]

    public init(budget: GenerationBudget, ledger: UsageLedger = UsageLedger()) {
        self.budget = budget
        self.ledger = ledger
    }

    public var currentLedger: UsageLedger { ledger }

    public var remaining: BudgetRemaining {
        BudgetRemaining(
            languageModelCalls: budget.maximumLanguageModelCalls - spentLanguageModelCalls,
            imageCalls: budget.maximumImageCalls - spentImageCalls,
            tokens: budget.maximumTokens - spentTokens,
            costUSD: budget.maximumCostUSD - spentCost
        )
    }

    /// Whether an estimate would fit, without claiming anything.
    public func canAfford(_ estimate: UsageEstimate) -> Bool {
        shortfall(for: estimate) == nil
    }

    /// Claims headroom, or throws naming the ceiling that would break.
    @discardableResult
    public func reserve(_ estimate: UsageEstimate) throws -> BudgetReservation {
        if let shortfall = shortfall(for: estimate) {
            throw StoryEngineError.budgetExhausted(shortfall)
        }
        let reservation = BudgetReservation(id: UUID(), estimate: estimate)
        outstanding[reservation.id] = estimate
        return reservation
    }

    /// Settles a reservation with what the call actually cost.
    public func commit(_ reservation: BudgetReservation, usage: AIUsage) {
        outstanding.removeValue(forKey: reservation.id)
        ledger.record(usage)
    }

    /// Releases a reservation whose call never happened, or failed without cost.
    public func release(_ reservation: BudgetReservation) {
        outstanding.removeValue(forKey: reservation.id)
    }

    /// Records spend that happened outside a reservation, e.g. a failed call
    /// the provider still billed for.
    public func record(_ usage: AIUsage) {
        ledger.record(usage)
    }

    // MARK: - Accounting

    private var spentLanguageModelCalls: Int {
        ledger.languageModelCallCount + outstanding.values.filter { !$0.isImageCall }.count
    }

    private var spentImageCalls: Int {
        ledger.imageCallCount + outstanding.values.filter(\.isImageCall).count
    }

    private var spentTokens: Int {
        ledger.totalTokens + outstanding.values.reduce(0) { $0 + $1.tokens }
    }

    private var spentCost: Double {
        ledger.totalCostUSD + outstanding.values.reduce(0) { $0 + $1.costUSD }
    }

    private func shortfall(for estimate: UsageEstimate) -> BudgetShortfall? {
        if estimate.isImageCall {
            let remaining = budget.maximumImageCalls - spentImageCalls
            if remaining < 1 {
                return BudgetShortfall(limit: .imageCalls, requested: 1, remaining: Double(remaining))
            }
        } else {
            let remaining = budget.maximumLanguageModelCalls - spentLanguageModelCalls
            if remaining < 1 {
                return BudgetShortfall(limit: .languageModelCalls, requested: 1, remaining: Double(remaining))
            }
        }

        let tokensLeft = budget.maximumTokens - spentTokens
        if estimate.tokens > tokensLeft {
            return BudgetShortfall(limit: .tokens, requested: Double(estimate.tokens), remaining: Double(tokensLeft))
        }

        let costLeft = budget.maximumCostUSD - spentCost
        if estimate.costUSD > costLeft {
            return BudgetShortfall(limit: .costUSD, requested: estimate.costUSD, remaining: costLeft)
        }

        return nil
    }
}
