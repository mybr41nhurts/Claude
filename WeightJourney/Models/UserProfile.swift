import Foundation
import SwiftData

enum UnitSystem: String, Codable, CaseIterable, Identifiable {
    case metric
    case imperial

    var id: String { rawValue }
    var weightUnitLabel: String { self == .metric ? "kg" : "lb" }
    var heightUnitLabel: String { self == .metric ? "cm" : "ft/in" }
}

@Model
final class UserProfile {
    var heightCm: Double
    var unitSystemRaw: String
    var dateOfBirth: Date?
    var createdAt: Date

    var unitSystem: UnitSystem {
        get { UnitSystem(rawValue: unitSystemRaw) ?? .imperial }
        set { unitSystemRaw = newValue.rawValue }
    }

    init(heightCm: Double, unitSystem: UnitSystem = .imperial, dateOfBirth: Date? = nil) {
        self.heightCm = heightCm
        self.unitSystemRaw = unitSystem.rawValue
        self.dateOfBirth = dateOfBirth
        self.createdAt = .now
    }
}
