import Foundation

struct ForecastResult {
    /// Rate of change from the linear regression, in kilograms per day.
    /// Negative values mean the trend is losing weight.
    let slopeKgPerDay: Double
    /// Projected date the goal weight will be reached, if the trend supports one.
    let projectedDate: Date?
    /// A human readable reason no projection is available, if `projectedDate` is nil.
    let reason: String?
}

/// Projects a future weight-loss/gain date using ordinary least squares
/// regression over a recent window of weigh-ins.
enum ForecastEngine {
    static func forecast(entries: [WeightEntry], goalWeightKg: Double?, lookbackDays: Int = 42) -> ForecastResult {
        let sorted = entries.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else {
            return ForecastResult(slopeKgPerDay: 0, projectedDate: nil, reason: "Log at least two weigh-ins to see a forecast.")
        }

        let cutoff = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: .now) ?? .distantPast
        var windowed = sorted.filter { $0.date >= cutoff }
        if windowed.count < 3 {
            windowed = Array(sorted.suffix(min(10, sorted.count)))
        }
        guard windowed.count >= 2 else {
            return ForecastResult(slopeKgPerDay: 0, projectedDate: nil, reason: "Not enough recent data to forecast.")
        }

        let referenceDate = windowed.first!.date
        let points = windowed.map { entry -> (x: Double, y: Double) in
            let days = entry.date.timeIntervalSince(referenceDate) / 86400
            return (days, entry.weightKg)
        }

        let n = Double(points.count)
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        let sumXY = points.reduce(0) { $0 + $1.x * $1.y }
        let sumXX = points.reduce(0) { $0 + $1.x * $1.x }

        let denominator = n * sumXX - sumX * sumX
        guard denominator != 0 else {
            return ForecastResult(slopeKgPerDay: 0, projectedDate: nil, reason: "Not enough weight variation yet to forecast.")
        }

        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n

        guard let goalWeightKg else {
            return ForecastResult(slopeKgPerDay: slope, projectedDate: nil, reason: nil)
        }

        guard abs(slope) > 0.0005 else {
            return ForecastResult(slopeKgPerDay: slope, projectedDate: nil, reason: "Your weight has been steady, so a target date can't be estimated yet.")
        }

        let currentTrendWeight = slope * points.last!.x + intercept
        let goalIsBelowCurrent = goalWeightKg < currentTrendWeight
        let trendIsDownward = slope < 0

        guard goalIsBelowCurrent == trendIsDownward else {
            return ForecastResult(slopeKgPerDay: slope, projectedDate: nil, reason: "Your current trend is moving away from your goal.")
        }

        let daysFromReferenceToGoal = (goalWeightKg - intercept) / slope
        let projectedDate = referenceDate.addingTimeInterval(daysFromReferenceToGoal * 86400)

        return ForecastResult(slopeKgPerDay: slope, projectedDate: projectedDate, reason: nil)
    }

    /// Predicted weight (kg) on a future date, extrapolating the current trend line.
    static func projectedWeight(entries: [WeightEntry], on date: Date, lookbackDays: Int = 42) -> Double? {
        let sorted = entries.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else { return nil }

        let cutoff = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: .now) ?? .distantPast
        var windowed = sorted.filter { $0.date >= cutoff }
        if windowed.count < 3 {
            windowed = Array(sorted.suffix(min(10, sorted.count)))
        }
        guard windowed.count >= 2 else { return nil }

        let referenceDate = windowed.first!.date
        let points = windowed.map { entry -> (x: Double, y: Double) in
            (entry.date.timeIntervalSince(referenceDate) / 86400, entry.weightKg)
        }
        let n = Double(points.count)
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        let sumXY = points.reduce(0) { $0 + $1.x * $1.y }
        let sumXX = points.reduce(0) { $0 + $1.x * $1.x }
        let denominator = n * sumXX - sumX * sumX
        guard denominator != 0 else { return nil }
        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n
        let x = date.timeIntervalSince(referenceDate) / 86400
        return slope * x + intercept
    }
}
