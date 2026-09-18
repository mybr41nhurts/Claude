import Foundation

enum UnitConversion {
    static func kgToLb(_ kg: Double) -> Double { kg * 2.2046226218 }
    static func lbToKg(_ lb: Double) -> Double { lb / 2.2046226218 }
    static func cmToInches(_ cm: Double) -> Double { cm / 2.54 }
    static func inchesToCm(_ inches: Double) -> Double { inches * 2.54 }

    static func displayWeight(_ kg: Double, unit: UnitSystem) -> Double {
        unit == .metric ? kg : kgToLb(kg)
    }

    static func weightToKg(_ value: Double, unit: UnitSystem) -> Double {
        unit == .metric ? value : lbToKg(value)
    }

    static func formattedWeight(_ kg: Double, unit: UnitSystem, fractionDigits: Int = 1) -> String {
        let value = displayWeight(kg, unit: unit)
        return String(format: "%.\(fractionDigits)f %@", value, unit.weightUnitLabel)
    }

    static func formattedHeight(_ cm: Double, unit: UnitSystem) -> String {
        switch unit {
        case .metric:
            return String(format: "%.0f cm", cm)
        case .imperial:
            let totalInches = cmToInches(cm)
            let feet = Int(totalInches / 12)
            let inches = (totalInches - Double(feet * 12)).rounded()
            return "\(feet)' \(Int(inches))\""
        }
    }

    static func heightFromFeetInches(feet: Int, inches: Double) -> Double {
        inchesToCm(Double(feet) * 12 + inches)
    }
}
