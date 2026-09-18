import Foundation
import SwiftData

@Model
final class Milestone {
    var order: Int
    var targetWeightKg: Double
    var goal: WeightGoal?

    init(order: Int, targetWeightKg: Double, goal: WeightGoal? = nil) {
        self.order = order
        self.targetWeightKg = targetWeightKg
        self.goal = goal
    }

    func isAchieved(latestWeightKg: Double?, isLossGoal: Bool) -> Bool {
        guard let latestWeightKg else { return false }
        return isLossGoal ? latestWeightKg <= targetWeightKg : latestWeightKg >= targetWeightKg
    }

    func achievedDate(entries: [WeightEntry], isLossGoal: Bool) -> Date? {
        let sorted = entries.sorted { $0.date < $1.date }
        for entry in sorted {
            let hit = isLossGoal ? entry.weightKg <= targetWeightKg : entry.weightKg >= targetWeightKg
            if hit { return entry.date }
        }
        return nil
    }
}
