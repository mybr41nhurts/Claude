import Foundation

enum MilestoneGenerator {
    /// Evenly spaces `count` milestones (by weight) between the start and target weight.
    static func generate(startWeightKg: Double, targetWeightKg: Double, count: Int) -> [Milestone] {
        guard count > 0, startWeightKg != targetWeightKg else { return [] }
        let step = (targetWeightKg - startWeightKg) / Double(count)
        return (1...count).map { index in
            Milestone(order: index, targetWeightKg: startWeightKg + step * Double(index))
        }
    }
}
