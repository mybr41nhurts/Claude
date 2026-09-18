import SwiftUI

enum BMICategory: String {
    case underweight = "Underweight"
    case normal = "Normal"
    case overweight = "Overweight"
    case obese = "Obese"

    var color: Color {
        switch self {
        case .underweight: return .blue
        case .normal: return .green
        case .overweight: return .orange
        case .obese: return .red
        }
    }
}

enum BMICalculator {
    static func bmi(weightKg: Double, heightCm: Double) -> Double {
        guard heightCm > 0 else { return 0 }
        let heightM = heightCm / 100
        return weightKg / (heightM * heightM)
    }

    static func category(for bmi: Double) -> BMICategory {
        switch bmi {
        case ..<18.5: return .underweight
        case 18.5..<25: return .normal
        case 25..<30: return .overweight
        default: return .obese
        }
    }
}
