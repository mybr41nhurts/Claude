import Foundation
import SwiftData

@Model
final class WeightGoal {
    var startDate: Date
    var startWeightKg: Double
    var targetWeightKg: Double
    var targetDate: Date?
    var isActive: Bool
    var milestoneCount: Int

    @Relationship(deleteRule: .cascade, inverse: \Milestone.goal)
    var milestones: [Milestone] = []

    init(
        startDate: Date,
        startWeightKg: Double,
        targetWeightKg: Double,
        targetDate: Date? = nil,
        isActive: Bool = true,
        milestoneCount: Int = 5
    ) {
        self.startDate = startDate
        self.startWeightKg = startWeightKg
        self.targetWeightKg = targetWeightKg
        self.targetDate = targetDate
        self.isActive = isActive
        self.milestoneCount = milestoneCount
    }

    var totalChangeKg: Double { targetWeightKg - startWeightKg }
    var isLossGoal: Bool { targetWeightKg < startWeightKg }

    func progress(currentWeightKg: Double) -> Double {
        guard totalChangeKg != 0 else { return 1 }
        let achieved = currentWeightKg - startWeightKg
        let fraction = achieved / totalChangeKg
        return min(max(fraction, 0), 1)
    }
}
