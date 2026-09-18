import Foundation
import SwiftData

@Model
final class WeightEntry {
    var date: Date
    var weightKg: Double
    var note: String?

    init(date: Date, weightKg: Double, note: String? = nil) {
        self.date = date
        self.weightKg = weightKg
        self.note = note
    }
}
